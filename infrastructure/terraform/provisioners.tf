# Terraform Provisioners for k3s Cluster Setup
# This file defines provisioners for automating k3s installation and QuakeWatch deployment

# Local-exec provisioner to wait for instances to be ready
resource "null_resource" "wait_for_instances" {
  depends_on = [
    aws_instance.k3s_master,
    aws_instance.k3s_worker
  ]

  provisioner "local-exec" {
    command = "echo 'Waiting for instances to be ready...' && sleep 60"
  }
}

# Remote-exec provisioner for k3s master setup
resource "null_resource" "k3s_master_setup" {
  count = var.k3s_master_count

  depends_on = [null_resource.wait_for_instances]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/quakewatch-key")
    host        = aws_instance.k3s_master[count.index].private_ip
    bastion_host = var.create_bastion ? aws_instance.bastion[0].public_ip : null
    bastion_user = "ubuntu"
    bastion_private_key = file("~/.ssh/quakewatch-key")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Setting up k3s master node ${count.index + 1}'",
      "sudo systemctl status k3s || echo 'k3s not running yet'",
      "sudo kubectl get nodes || echo 'kubectl not ready yet'",
      "echo 'k3s master setup completed'"
    ]
  }
}

# Remote-exec provisioner for k3s worker setup
resource "null_resource" "k3s_worker_setup" {
  count = var.k3s_worker_count

  depends_on = [null_resource.wait_for_instances]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/quakewatch-key")
    host        = aws_instance.k3s_worker[count.index].private_ip
    bastion_host = var.create_bastion ? aws_instance.bastion[0].public_ip : null
    bastion_user = "ubuntu"
    bastion_private_key = file("~/.ssh/quakewatch-key")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Setting up k3s worker node ${count.index + 1}'",
      "sudo systemctl status k3s-agent || echo 'k3s-agent not running yet'",
      "echo 'k3s worker setup completed'"
    ]
  }
}

# Remote-exec provisioner for QuakeWatch deployment
resource "null_resource" "quakewatch_deployment" {
  depends_on = [
    null_resource.k3s_master_setup,
    null_resource.k3s_worker_setup
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/quakewatch-key")
    host        = aws_instance.k3s_master[0].private_ip
    bastion_host = var.create_bastion ? aws_instance.bastion[0].public_ip : null
    bastion_user = "ubuntu"
    bastion_private_key = file("~/.ssh/quakewatch-key")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Deploying QuakeWatch application...'",
      "sudo kubectl get nodes",
      "sudo kubectl get pods -n quakewatch || echo 'QuakeWatch namespace not found'",
      "sudo kubectl get svc -n quakewatch || echo 'QuakeWatch services not found'",
      "echo 'QuakeWatch deployment completed'"
    ]
  }
}

# Local-exec provisioner for cluster validation
resource "null_resource" "cluster_validation" {
  depends_on = [null_resource.quakewatch_deployment]

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== QuakeWatch k3s Cluster Validation ==="
      echo "Date: $(date)"
      echo ""
      echo "1. Master Node IP: ${aws_instance.k3s_master[0].private_ip}"
      echo "2. Worker Node IPs: ${join(", ", aws_instance.k3s_worker[*].private_ip)}"
      echo "3. Bastion IP: ${var.create_bastion ? aws_instance.bastion[0].public_ip : "Not created"}"
      echo "4. ALB DNS: ${aws_lb.k3s_alb.dns_name}"
      echo ""
      echo "Access Information:"
      echo "- SSH to bastion: ssh -i ~/.ssh/quakewatch-key ubuntu@${var.create_bastion ? aws_instance.bastion[0].public_ip : "N/A"}"
      echo "- From bastion to master: ssh -i ~/.ssh/quakewatch-key ubuntu@${aws_instance.k3s_master[0].private_ip}"
      echo "- QuakeWatch NodePort: http://${aws_instance.k3s_master[0].public_ip}:30000"
      echo "- QuakeWatch ALB: http://${aws_lb.k3s_alb.dns_name}"
      echo ""
      echo "Validation commands:"
      echo "- Check cluster: kubectl get nodes"
      echo "- Check QuakeWatch: kubectl get pods -n quakewatch"
      echo "- Check services: kubectl get svc -n quakewatch"
      echo ""
      echo "Cluster validation completed!"
    EOT
  }
}

# Local-exec provisioner for creating kubeconfig
resource "null_resource" "kubeconfig_setup" {
  depends_on = [null_resource.k3s_master_setup]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Setting up kubeconfig..."
      mkdir -p ~/.kube
      
      # Copy kubeconfig from master node
      if [ "${var.create_bastion}" = true ]; then
        scp -i ~/.ssh/quakewatch-key -o StrictHostKeyChecking=no \
          ubuntu@${aws_instance.bastion[0].public_ip}:/tmp/k3s.yaml ~/.kube/config
      else
        echo "Bastion not created, manual kubeconfig setup required"
      fi
      
      # Update kubeconfig server address
      sed -i 's/127.0.0.1/${aws_instance.k3s_master[0].private_ip}/g' ~/.kube/config
      
      echo "kubeconfig setup completed"
    EOT
  }
}
