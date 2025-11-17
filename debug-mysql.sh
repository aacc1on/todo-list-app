#!/bin/bash

echo "🔍 Debugging MySQL Deployment..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check storage class
echo -e "${BLUE}1. Checking StorageClass...${NC}"
kubectl get storageclass
echo ""

# Check PVC
echo -e "${BLUE}2. Checking PersistentVolumeClaim...${NC}"
kubectl get pvc -n todoapp
echo ""

# Check PV
echo -e "${BLUE}3. Checking PersistentVolume...${NC}"
kubectl get pv
echo ""

# Check pod status
echo -e "${BLUE}4. MySQL Pod Status...${NC}"
kubectl get pods -n todoapp -l app=mysql
echo ""

# Describe pod
echo -e "${BLUE}5. Describe MySQL Pod...${NC}"
kubectl describe pod mysql-0 -n todoapp
echo ""

# Check events
echo -e "${BLUE}6. Recent Events...${NC}"
kubectl get events -n todoapp --sort-by='.lastTimestamp' | tail -20
echo ""

# Check logs
echo -e "${BLUE}7. MySQL Logs...${NC}"
if kubectl get pod mysql-0 -n todoapp &>/dev/null; then
    kubectl logs mysql-0 -n todoapp --tail=50
else
    echo -e "${RED}Pod mysql-0 not found${NC}"
fi
echo ""

# Check init container logs (if exists)
echo -e "${BLUE}8. Init Container Logs (if any)...${NC}"
kubectl logs mysql-0 -n todoapp -c init-db-check 2>/dev/null || echo "No init container or not started"
echo ""

# Suggestions
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Possible Solutions:${NC}"
echo ""
echo "1. If PVC is Pending:"
echo "   kubectl get pvc -n todoapp"
echo "   kubectl describe pvc mysql-data-mysql-0 -n todoapp"
echo ""
echo "2. Delete and recreate:"
echo "   kubectl delete statefulset mysql -n todoapp"
echo "   kubectl delete pvc mysql-data-mysql-0 -n todoapp"
echo "   kubectl apply -f k8s/04-mysql-statefulset-simple.yaml"
echo ""
echo "3. Check Minikube storage:"
echo "   minikube ssh"
echo "   df -h"
echo ""
echo "4. Try with hostPath (for local testing):"
echo "   See: fix-mysql-hostpath.yaml"