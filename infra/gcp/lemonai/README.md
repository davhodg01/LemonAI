# LemonAI GCP Deployment Runbook

## Overview
This directory contains Terraform configuration to deploy LemonAI on a minimal GCP Compute Engine instance (`f1-micro`). It secures the application behind an Nginx reverse proxy with HTTPS (self-signed) and Basic Authentication.

## Prerequisites
- GCP Account and Project
- `gcloud` CLI installed and authenticated
- `terraform` installed

## Quick Start from Cloud Shell (Recommended)

1.  **Clone the Repo**:
    ```bash
    git clone <your-repo-url>
    cd lemonai/infra/gcp/lemonai
    ```

2.  **Verify Configuration**:
    Check `terraform.tfvars`. It is pre-filled with:
    - **Project ID**: `nimble-factor-478021-b4`
    - **Admin CIDR**: `98.228.216.14/32`
    - **Credentials**: `admin` / `ChangeMe123!`

    > [!WARNING]
    > **Change the password!**
    > Edit `terraform.tfvars` and update `basic_auth_pass` to a strong unique password.

3.  **Initialize & Apply**:
    ```bash
    terraform init
    terraform apply
    ```
    Type `yes` when prompted.

4.  **Wait for Startup**:
    The VM takes 5-10 minutes to boot, install Docker, and start containers.

## Continuous Deployment (CI/CD)
This repository is configured with GitHub Actions to automatically deploy changes to Google Cloud.

### How it works
1.  Push changes to the `main` (or `infra/gcp-deployment`) branch.
2.  The workflow `.github/workflows/deploy.yaml` triggers.
3.  It authenticates via **Workload Identity Federation** (Keyless).
4.  It runs `terraform apply` automatically.

### Secrets Configuration
Required GitHub Action Secrets:
-   `WIF_PROVIDER_NAME`: (From `terraform output`)
-   `WIF_SERVICE_ACCOUNT`: (From `terraform output`)
-   `TF_VAR_BASIC_AUTH_PASS`: (Your secure password)

## Manual Verification

1.  **Get the Public IP**:
    It will be output at the end of `terraform apply`.
    ```bash
    terraform output public_ip
    ```

2.  **Access Web UI**:
    - Open `https://<PUBLIC_IP>/`
    - Accept the self-signed certificate warning (Advanced -> Proceed).
    - Login with your Basic Auth credentials.

3.  **Security Check**:
    - `http://<PUBLIC_IP>/` should redirect to HTTPS or be unreachable (depending on strict firewall, we allow port 80 for redirect in nginx config but firewall can block it. Check `main.tf`).
    - `http://<PUBLIC_IP>:5005` must be unreachable.

## Operations

### SSH Access
Only allowed from your Admin IP.
```bash
ssh -i ~/.ssh/google_compute_engine ubuntu@<PUBLIC_IP>
```
*(You may need to add your key to the project metadata or instance first via gcloud compute ssh)*

### View Logs
Inside the VM:
```bash
# Startup script logs
sudo journalctl -u google-startup-scripts.service -f

# Container logs
docker logs -f lemon-app
docker logs -f nginx-proxy
```

### Fallback Plan (If `f1-micro` crashes)
If the VM runs out of memory (OOM):
1.  Edit `variables.tf`.
2.  Change `machine_type` to `e2-micro` (Step 1) or `e2-small` (Step 2).
3.  Increase swap in `variables.tf` if needed.
4.  Run `terraform apply`.
