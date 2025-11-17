#!/bin/bash

set -e

echo "🚀 Starting TODO App Deployment to Kubernetes..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if minikube is running
echo -e "${BLUE}Checking Minikube status...${NC}"
if ! minikube status > /dev/null 2>&1; then
    echo -e "${RED}Minikube is not running. Starting...${NC}"
    minikube start --memory=4096 --cpus=2
fi

# Enable metrics server for HPA
echo -e "${BLUE}Enabling metrics-server...${NC}"
minikube addons enable metrics-server

# Enable ingress
echo -e "${BLUE}Enabling ingress...${NC}"
minikube addons enable ingress

# Build Docker image
echo -e "${BLUE}Building Docker image...${NC}"
docker build -t todoapp-backend:1.0.0 .

# Load image to Minikube
echo -e "${BLUE}Loading image to Minikube...${NC}"
minikube image load todoapp-backend:1.0.0

# Apply Kubernetes manifests
echo -e "${BLUE}Applying Kubernetes manifests...${NC}"

echo "  → Creating namespace..."
kubectl apply -f k8s/01-namespace.yaml

echo "  → Creating secrets..."
kubectl apply -f k8s/02-mysql-secret.yaml

echo "  → Creating configmaps..."
kubectl apply -f k8s/03-mysql-configmap.yaml
kubectl apply -f k8s/06-backend-configmap.yaml

echo "  → Deploying MySQL StatefulSet..."
kubectl apply -f k8s/04-mysql-statefulset-simple.yaml

echo "  → Waiting for MySQL to be ready..."
echo "    This may take 2-3 minutes for first initialization..."
kubectl wait --for=condition=ready pod -l app=mysql -n todoapp --timeout=300s || {
    echo -e "${RED}MySQL failed to start. Running diagnostics...${NC}"
    ./debug-mysql.sh
    exit 1
}

echo "  → Creating RBAC resources..."
kubectl apply -f k8s/05-backend-rbac.yaml

echo "  → Deploying backend..."
kubectl apply -f k8s/07-backend-deployment.yaml

echo "  → Creating HPA..."
kubectl apply -f k8s/08-backend-hpa.yaml

echo "  → Creating PDB..."
kubectl apply -f k8s/09-backend-pdb.yaml

echo "  → Creating Ingress..."
kubectl apply -f k8s/10-ingress.yaml

# Wait for backend to be ready
echo -e "${BLUE}Waiting for backend pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=todoapp-backend -n todoapp --timeout=180s

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Add to /etc/hosts (requires sudo)
echo -e "${BLUE}Adding todoapp.local to /etc/hosts...${NC}"
if grep -q "todoapp.local" /etc/hosts; then
    echo "Entry already exists in /etc/hosts"
else
    echo "$MINIKUBE_IP todoapp.local" | sudo tee -a /etc/hosts
fi

# Display status
echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo ""
echo "📊 Deployment Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get all -n todoapp
echo ""
echo "🌐 Access the application:"
echo "   http://todoapp.local"
echo ""
echo "📈 Useful commands:"
echo "   kubectl get pods -n todoapp -w"
echo "   kubectl logs -f -l app=todoapp-backend -n todoapp"
echo "   kubectl describe hpa todoapp-backend-hpa -n todoapp"
echo "   minikube dashboard"