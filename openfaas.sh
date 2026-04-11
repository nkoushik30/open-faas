#!/bin/bash

set -e
set -o pipefail

echo "🚀 OpenFaaS + Python Setup"

# -------------------------------
# Helper
# -------------------------------
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# -------------------------------
# 1. Fix APT Issues + Update
# -------------------------------
echo "📦 Fixing APT issues..."

# Remove problematic repos (safe cleanup)
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo rm -f /etc/apt/sources.list.d/mongodb-org-4.4.list

# Add MongoDB 7 key safely (if needed)
if [ ! -f /usr/share/keyrings/mongodb-server-7.0.gpg ]; then
  echo "🔑 Adding MongoDB key..."
  curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
    sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
fi

echo "📦 Updating system..."
sudo apt update -y || echo "⚠️ Ignoring APT warnings"

# -------------------------------
# 2. Install Basic Dependencies
# -------------------------------
echo "📦 Installing dependencies..."
sudo apt install -y curl apt-transport-https ca-certificates gnupg lsb-release

# -------------------------------
# 3. Docker
# -------------------------------
if command_exists docker; then
  echo "✅ Docker already installed"
else
  echo "🐳 Installing Docker..."
  sudo apt install -y docker.io
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker $USER
fi

# -------------------------------
# 4. kubectl
# -------------------------------
if command_exists kubectl; then
  echo "✅ kubectl already installed"
else
  echo "☸️ Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

# -------------------------------
# 5. Minikube
# -------------------------------
if command_exists minikube; then
  echo "✅ Minikube already installed"
else
  echo "📦 Installing Minikube..."
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
fi

# -------------------------------
# 6. Start Minikube
# -------------------------------
if minikube status 2>/dev/null | grep -q "Running"; then
  echo "✅ Minikube already running"
else
  echo "⚙️ Starting Minikube..."
  minikube start --driver=docker --memory=3072 --cpus=2
fi

# -------------------------------
# 7. Helm
# -------------------------------
if command_exists helm; then
  echo "✅ Helm already installed"
else
  echo "📦 Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# -------------------------------
# 8. OpenFaaS Repo
# -------------------------------
if helm repo list | grep -q openfaas; then
  echo "✅ OpenFaaS repo exists"
else
  echo "📦 Adding OpenFaaS repo..."
  helm repo add openfaas https://openfaas.github.io/faas-netes/
fi

helm repo update

# -------------------------------
# 9. Namespaces
# -------------------------------
kubectl get ns openfaas >/dev/null 2>&1 || kubectl create ns openfaas
kubectl get ns openfaas-fn >/dev/null 2>&1 || kubectl create ns openfaas-fn

# -------------------------------
# 10. OpenFaaS Install
# -------------------------------
if helm list -n openfaas | grep -q openfaas; then
  echo "✅ OpenFaaS already installed"
else
  echo "🚀 Installing OpenFaaS..."
  helm install openfaas openfaas/openfaas \
    --namespace openfaas \
    --set functionNamespace=openfaas-fn \
    --set generateBasicAuth=true \
    --set prometheus.enabled=false
fi

# -------------------------------
# 11. Wait for Pods
# -------------------------------
echo "⏳ Waiting for pods..."
kubectl wait --for=condition=Ready pod --all -n openfaas --timeout=300s

# -------------------------------
# 12. Gateway URL
# -------------------------------
echo "🌐 Getting OpenFaaS Gateway..."

MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc gateway-external -n openfaas -o jsonpath='{.spec.ports[0].nodePort}')

GATEWAY_URL="http://$MINIKUBE_IP:$NODE_PORT"

echo "🌐 Gateway URL: $GATEWAY_URL"

# -------------------------------
# 13. Password
# -------------------------------
PASSWORD=$(kubectl get secret -n openfaas basic-auth \
  -o jsonpath="{.data.basic-auth-password}" | base64 --decode)

echo "🔐 Username: admin"
echo "🔐 Password: $PASSWORD"

# -------------------------------
# 14. faas-cli
# -------------------------------
if command_exists faas-cli; then
  echo "✅ faas-cli already installed"
else
  echo "📦 Installing faas-cli..."
  curl -sL https://cli.openfaas.com | sudo sh
fi

# -------------------------------
# 15. Login
# -------------------------------
if faas-cli list --gateway $GATEWAY_URL >/dev/null 2>&1; then
  echo "✅ Already logged into OpenFaaS"
else
  echo "$PASSWORD" | faas-cli login \
    --username admin \
    --password-stdin \
    --gateway $GATEWAY_URL
fi

# -------------------------------
# 16. Python Template
# -------------------------------
if faas-cli template store list | grep -q python3-http; then
  echo "✅ Python template available"
else
  echo "🐍 Pulling Python template..."
  faas-cli template store pull python3-http
fi

# -------------------------------
# 17. Function Creation
# -------------------------------
FN="python-fn"

if [ -d "$FN" ]; then
  echo "✅ Function folder exists"
else
  echo "🚀 Creating function..."
  faas-cli new $FN --lang python3-http
fi

# -------------------------------
# 18. Handler Update
# -------------------------------
if ! grep -q "Hello from Python FaaS" "$FN/handler.py"; then
  echo "✍️ Updating handler..."
  cat > $FN/handler.py <<EOF
def handle(event, context):
    return {
        "statusCode": 200,
        "body": {
            "message": "Hello from Python FaaS 🚀",
            "input": str(event.body)
        }
    }
EOF
else
  echo "✅ Handler already updated"
fi

# -------------------------------
# 19. Docker Login
# -------------------------------
DOCKER_USER=$(docker info 2>/dev/null | grep Username | awk '{print $2}')

if [ -z "$DOCKER_USER" ]; then
  echo "⚠️ Please login to Docker:"
  docker login
  DOCKER_USER=$(docker info | grep Username | awk '{print $2}')
fi

# -------------------------------
# 20. Update Image Name
# -------------------------------
if ! grep -q "$DOCKER_USER/$FN" "$FN.yml"; then
  echo "✍️ Updating image name..."
  sed -i "s|image: .*|image: $DOCKER_USER/$FN:latest|" $FN.yml
else
  echo "✅ Image already configured"
fi

# -------------------------------
# 21. Deploy Function
# -------------------------------
echo "🚀 Deploying function..."
faas-cli up -f $FN.yml --gateway $GATEWAY_URL

# -------------------------------
# DONE
# -------------------------------
echo "🎉 DONE!"
echo "👉 Test URL:"
echo "$GATEWAY_URL/function/$FN"
