#!/bin/bash

set -e

echo "🚀 Starting OpenFaaS Setup..."

# -------------------------------
# 1. Update System
# -------------------------------
echo "📦 Updating system..."
sudo apt update -y

# -------------------------------
# 2. Install Docker
# -------------------------------
echo "🐳 Installing Docker..."
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# -------------------------------
# 3. Install kubectl
# -------------------------------
echo "☸️ Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# -------------------------------
# 4. Install Minikube
# -------------------------------
echo "📦 Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# -------------------------------
# 5. Start Minikube
# -------------------------------
echo "⚙️ Starting Minikube..."
minikube start --driver=docker --memory=4096 --cpus=2

# -------------------------------
# 6. Install Helm
# -------------------------------
echo "📦 Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# -------------------------------
# 7. Add OpenFaaS Repo
# -------------------------------
echo "📦 Adding OpenFaaS Helm repo..."
helm repo add openfaas https://openfaas.github.io/faas-netes/
helm repo update

# -------------------------------
# 8. Create Namespaces
# -------------------------------
echo "📁 Creating namespaces..."
kubectl create namespace openfaas || true
kubectl create namespace openfaas-fn || true

# -------------------------------
# 9. Install OpenFaaS (No Prometheus)
# -------------------------------
echo "🚀 Installing OpenFaaS..."
helm install openfaas openfaas/openfaas \
  --namespace openfaas \
  --set functionNamespace=openfaas-fn \
  --set generateBasicAuth=true \
  --set prometheus.enabled=false

# -------------------------------
# 10. Wait for Pods
# -------------------------------
echo "⏳ Waiting for OpenFaaS pods..."
kubectl wait --for=condition=Ready pod --all -n openfaas --timeout=300s

# -------------------------------
# 11. Get Gateway URL
# -------------------------------
echo "🌐 Getting OpenFaaS Gateway URL..."
minikube service gateway-external -n openfaas --url

# -------------------------------
# 12. Get Password
# -------------------------------
echo "🔐 OpenFaaS Login Details:"
PASSWORD=$(kubectl get secret -n openfaas basic-auth \
  -o jsonpath="{.data.basic-auth-password}" | base64 --decode)

echo "-----------------------------------"
echo "Username: admin"
echo "Password: $PASSWORD"
echo "-----------------------------------"

echo "✅ OpenFaaS Setup Completed!"
echo "👉 Open the above URL in browser"
