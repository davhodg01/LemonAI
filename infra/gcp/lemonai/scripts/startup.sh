#!/bin/bash
set -e

# --- Configuration ---
SWAP_SIZE="${SWAP_SIZE}"
BASIC_AUTH_USER="${BASIC_AUTH_USER}"
BASIC_AUTH_PASS="${BASIC_AUTH_PASS}"
STATIC_IP="${STATIC_IP}"
LEMON_IMAGE="hexdolemonai/lemon:latest"

# --- Install Docker ---
echo "Installing Docker..."
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# --- Setup Directories ---
echo "Creating directories..."
mkdir -p /opt/lemon/workspace
mkdir -p /opt/lemon/data
mkdir -p /opt/lemon/cache
mkdir -p /opt/lemon/nginx/ssl

# --- Setup Swap ---
if ! grep -q "swapfile" /etc/fstab; then
  echo "Setting up ${SWAP_SIZE}GB swap..."
  fallocate -l "${SWAP_SIZE}G" /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
  sysctl vm.swappiness=10
  echo 'vm.swappiness=10' >> /etc/sysctl.conf
else
  echo "Swap already configured."
fi

# --- Nginx Configuration ---
echo "Configuring Nginx..."

# Generate Self-Signed Cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /opt/lemon/nginx/ssl/nginx.key \
  -out /opt/lemon/nginx/ssl/nginx.crt \
  -subj "/CN=${STATIC_IP}"

# Create Basic Auth File
echo "${BASIC_AUTH_PASS}" | htpasswd -ic /opt/lemon/nginx/.htpasswd "${BASIC_AUTH_USER}"

# Nginx Config
cat <<EOF > /opt/lemon/nginx/nginx.conf
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name _;
        return 301 https://\$host\$request_uri;
    }

    server {
        listen 443 ssl;
        server_name _;

        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

        location / {
            auth_basic "Restricted Access";
            auth_basic_user_file /etc/nginx/.htpasswd;

            proxy_pass http://host.docker.internal:5005;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

# --- Start Containers ---
echo "Starting containers..."

# Stop existing containers if running (cleanup)
docker stop lemon-app nginx-proxy || true
docker rm lemon-app nginx-proxy || true

# Run LemonAI
# Note: Assuming host.docker.internal works on Linux with --add-host (standard on newer docker versions)
docker run -d \
  --name lemon-app \
  --restart unless-stopped \
  -p 127.0.0.1:5005:5005 \
  -e DOCKER_HOST_ADDR=host.docker.internal \
  -e ACTUAL_HOST_WORKSPACE_PATH=/opt/lemon/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /opt/lemon/workspace:/workspace \
  -v /opt/lemon/data:/app/data \
  -v /opt/lemon/cache:/.cache \
  $LEMON_IMAGE

# Run Nginx
docker run -d \
  --name nginx-proxy \
  --restart unless-stopped \
  -p 80:80 \
  -p 443:443 \
  --add-host host.docker.internal:host-gateway \
  -v /opt/lemon/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v /opt/lemon/nginx/ssl:/etc/nginx/ssl:ro \
  -v /opt/lemon/nginx/.htpasswd:/etc/nginx/.htpasswd:ro \
  nginx:alpine

echo "Startup complete!"
