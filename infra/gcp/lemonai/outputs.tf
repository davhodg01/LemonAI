output "public_ip" {
  description = "The static public IP address of the LemonAI instance"
  value       = google_compute_address.static_ip.address
}

output "instance_self_link" {
  description = "The self link of the compute instance"
  value       = google_compute_instance.vm.self_link
}

output "ssh_command" {
  value = "ssh -i <your-key> ubuntu@${google_compute_address.static_ip.address}"
}

output "wif_provider_name" {
  description = "Workload Identity Provider Resource Name"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "service_account_email" {
  description = "Service Account Email for GitHub Actions"
  value       = google_service_account.github_actions.email
}
