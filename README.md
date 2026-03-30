# 🚀 OpenFaaS Python Function Deployment (Kubernetes + Minikube)

This project demonstrates how to set up **OpenFaaS on Kubernetes (Minikube)** and deploy a **Python-based serverless function**.

---

## 📌 Prerequisites

Make sure your system has:

- Linux (Ubuntu recommended)
- Internet connection
- Sudo access

---

## ⚙️ 1. Clone the Repository

```bash
git clone <your-repo-link>
cd <repo-folder>
```

---

## 🚀 2. Run Setup Script

Make the script executable:

```bash
chmod +x setup-openfaas.sh
```

Run the script:

```bash
./setup-openfaas.sh
```

---

## 🧠 What This Script Does

The script automatically:

- Installs Docker (if not present)
- Installs kubectl
- Installs Minikube
- Starts Kubernetes cluster
- Installs Helm
- Deploys OpenFaaS (without Prometheus)
- Installs faas-cli
- Creates a Python function
- Deploys the function

---

## 🌐 3. Access OpenFaaS Dashboard

Run:

```bash
kubectl port-forward svc/gateway -n openfaas 8080:8080
```

Open browser:

```
http://127.0.0.1:8080
```

⚠️ Keep terminal running

---

## 🔐 4. Get Login Credentials

```bash
kubectl get secret -n openfaas basic-auth \
-o jsonpath="{.data.basic-auth-password}" | base64 --decode
```

Login with:

- Username: `admin`
- Password: (command output)

---

## 🧪 5. Test the Function

### Option 1: Browser

```
http://127.0.0.1:8080/function/python-fn
```

---

### Option 2: curl

```bash
curl //outputURL
```

---

## 📁 Project Structure

```
.
├── setup-openfaas.sh
├── python-fn/
│   ├── handler.py
│   └── requirements.txt
├── python-fn.yml
└── README.md
```

---

## 🔧 6. Modify Function

Edit:

```bash
python-fn/handler.py
```

Example:

```python
def handle(event, context):
    return {
        "statusCode": 200,
        "body": "Hello from custom function 🚀"
    }
```

---

## 🔄 7. Redeploy Function

```bash
faas-cli up -f python-fn.yml --gateway http://127.0.0.1:8080
```

---

## 📊 8. Monitor Logs

```bash
kubectl logs -f -n openfaas-fn deploy/python-fn
```

---

## ⚠️ Common Issues

### ❌ Cannot access Minikube IP

✔ Use port-forward instead

---

### ❌ Docker push failed

```bash
docker login
```

---

### ❌ Function not updating

```bash
faas-cli build -f python-fn.yml
faas-cli push -f python-fn.yml
faas-cli deploy -f python-fn.yml
```

---

## 🧠 Architecture

```
User → OpenFaaS Gateway → Kubernetes Pod → Python Function
```

---

## 🎯 Features

- Fully automated setup
- Idempotent script (safe to rerun)
- Python serverless function
- Kubernetes-based deployment

---

## 🚀 Future Improvements

- Add CI/CD pipeline
- Integrate Firebase / DB
- Add monitoring (Prometheus + Grafana)
- Auto-scaling (HPA)

---

## 👨‍💻 Author

Koushik Nelluri

---

## ⭐ If this helped you, give it a star!
