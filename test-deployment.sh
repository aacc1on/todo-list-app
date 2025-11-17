#!/bin/bash

echo "🧪 Testing TODO App Deployment..."

# Test 1: Check all pods are running
echo "1️⃣ Checking pod status..."
kubectl get pods -n todoapp

# Test 2: Test backend health
echo ""
echo "2️⃣ Testing backend health endpoint..."
kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n todoapp -- \
  curl -s http://todoapp-backend:3000/items

# Test 3: Check HPA status
echo ""
echo "3️⃣ Checking HPA status..."
kubectl get hpa -n todoapp

# Test 4: Check PDB status
echo ""
echo "4️⃣ Checking Pod Disruption Budget..."
kubectl get pdb -n todoapp

# Test 5: Check resource usage
echo ""
echo "5️⃣ Resource usage..."
kubectl top pods -n todoapp

# Test 6: Check logs
echo ""
echo "6️⃣ Recent logs from backend..."
kubectl logs -l app=todoapp-backend -n todoapp --tail=20

# Test 7: Load testing (optional)
echo ""
echo "7️⃣ Load testing (creating 100 requests)..."
for i in {1..100}; do
  curl -s http://todoapp.local/items > /dev/null &
done
wait

echo ""
echo "Waiting 30 seconds for HPA to react..."
sleep 30

echo "HPA status after load:"
kubectl get hpa -n todoapp

echo ""
echo "Pod count after load:"
kubectl get pods -l app=todoapp-backend -n todoapp