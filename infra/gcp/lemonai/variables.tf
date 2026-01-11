variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "Compute Engine machine type"
  type        = string
  default     = "f1-micro"
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
}

variable "boot_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
}

variable "swap_size_gb" {
  description = "Swap size in GB"
  type        = number
  default     = 1
}

variable "admin_ssh_cidr" {
  description = "CIDR block allowed to SSH"
  type        = string
}

variable "basic_auth_user" {
  description = "Nginx Basic Auth Username"
  type        = string
  default     = "admin"
}

variable "basic_auth_pass" {
  description = "Nginx Basic Auth Password"
  type        = string
  sensitive   = true
}

variable "vm_name" {
  default = "lemonai-vm"
}

variable "static_ip_name" {
  default = "lemonai-ip"
}

variable "network_tag" {
  default = "lemonai-public"
}

variable "github_repo" {
  description = "The GitHub repository in 'owner/repo' format"
  type        = string
}
