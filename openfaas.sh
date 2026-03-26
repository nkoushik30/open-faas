#!/bin/bash

set -x

echo "🚀 Starting OpenFaaS Setup (Smart Mode)..."

# -------------------------------
# Helper Function
# -------------------------------
command_exists() {
  command -v "$1" >/dev/null 2>&1
}



# -------------------------------
# 1. Update System
# -------------------------------
echo "📦 Updating system..."
sudo apt update -y

# -------------------------------
# 2. Install Docker
# -------------------------------
if command_exists docker; then
  echo "✅ Docker already installed. Skipping..."
else
  echo "🐳 Installing Docker..."
  sudo apt install -y docker.io
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -aG docker $USER
fi

# -------------------------------
# 3. Install kubectl
# -------------------------------
if command_exists kubectl; then
  echo "✅ kubectl already installed. Skipping..."
else
  echo "☸️ Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

# -------------------------------
# 4. Install Minikube
# -------------------------------
if command_exists minikube; then
  echo "✅ Minikube already installed. Skipping..."
else
  echo "📦 Installing Minikube..."
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
fi

# -------------------------------
# 5. Start Minikube (if not running)
# -------------------------------
if minikube status | grep -q "Running"; then
  echo "✅ Minikube already running. Skipping start..."
else
  echo "⚙️ Starting Minikube..."
  minikube start --driver=docker --memory=4096 --cpus=2
fi

# -------------------------------
# 6. Install Helm
# -------------------------------
if command_exists helm; then
  echo "✅ Helm already installed. Skipping..."
else
  echo "📦 Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# -------------------------------
# 7. Add OpenFaaS Repo
# -------------------------------
if helm repo list | grep -q openfaas; then
  echo "✅ OpenFaaS repo already added. Skipping..."
else
  echo "📦 Adding OpenFaaS Helm repo..."
  helm repo add openfaas https://openfaas.github.io/faas-netes/
fi

helm repo update

# -------------------------------
# 8. Create Namespaces
# -------------------------------
if kubectl get namespace openfaas >/dev/null 2>&1; then
  echo "✅ Namespace openfaas exists"
else
  kubectl create namespace openfaas
fi

if kubectl get namespace openfaas-fn >/dev/null 2>&1; then
  echo "✅ Namespace openfaas-fn exists"
else
  kubectl create namespace openfaas-fn
fi

# -------------------------------
# 9. Install OpenFaaS
# -------------------------------
if helm list -n openfaas | grep -q openfaas; then
  echo "✅ OpenFaaS already installed. Skipping..."
else
  echo "🚀 Installing OpenFaaS..."
  helm install openfaas openfaas/openfaas \
    --namespace openfaas \
    --set functionNamespace=openfaas-fn \
    --set generateBasicAuth=true \
    --set prometheus.enabled=false
fi

# -------------------------------
# 10. Wait for Pods
# -------------------------------
echo "⏳ Waiting for OpenFaaS pods..."
kubectl wait --for=condition=Ready pod --all -n openfaas --timeout=300s

# -------------------------------
# 11. Get Gateway URL
# -------------------------------
echo "🌐 Getting OpenFaaS Gateway URL..."
GATEWAY_URL=$(minikube service gateway-external -n openfaas --url)
echo "Gateway URL: $GATEWAY_URL"

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
echo "👉 Open: $GATEWAY_URL"
