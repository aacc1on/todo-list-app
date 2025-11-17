# Example to-do List Application

This repository is a simple to-do list manager that runs on Node.js.

## Getting started

Download [Docker Desktop](https://www.docker.com/products/docker-desktop) for Mac or Windows. Docker Compose will be automatically installed. 
On Linux, make sure you have the latest version of [Compose](https://docs.docker.com/compose/install/).

## Clone the repository

Open a terminal and clone this sample application.

```
 git clone https://github.com/dockersamples/todo-list-app
```

## Run the app

Navigate into the todo-list-app directory:

```
docker compose up -d --build
```

When you run this command, you should see an output like this:

```
[+] Running 4/4
✔ app 3 layers [⣿⣿⣿]      0B/0B            Pulled           7.1s
  ✔ e6f4e57cc59e Download complete                          0.9s
  ✔ df998480d81d Download complete                          1.0s
  ✔ 31e174fedd23 Download complete                          2.5s
[+] Running 2/4
  ⠸ Network todo-list-app_default           Created         0.3s
  ⠸ Volume "todo-list-app_todo-mysql-data"  Created         0.3s
  ✔ Container todo-list-app-app-1           Started         0.3s
  ✔ Container todo-list-app-mysql-1         Started         0.3s
```

## List the services

```
docker compose ps
NAME                    IMAGE            COMMAND                  SERVICE   CREATED          STATUS          PORTS
todo-list-app-app-1     node:18-alpine   "docker-entrypoint.s…"   app       24 seconds ago   Up 7 seconds    127.0.0.1:3000->3000/tcp
todo-list-app-mysql-1   mysql:8.0        "docker-entrypoint.s…"   mysql     24 seconds ago   Up 23 seconds   3306/tcp, 33060/tcp
```

If you look at the Docker Desktop GUI, you can see the containers and dive deeper into their configuration.




<img width="1330" alt="image" src="https://github.com/dockersamples/todo-list-app/assets/313480/d85a4bcf-e2c3-4917-9220-7d9b9a78dc54">


## Access the app

The to-do list app will be running at [http://localhost:3000](http://localhost:3000).


# TODO App - Kubernetes Deployment Guide

## 📁 Project Structure

```
todoapp/
├── src/                          # Application source code
├── Dockerfile                    # Optimized multi-stage Dockerfile
├── k8s/                          # Kubernetes manifests
│   ├── 01-namespace.yaml
│   ├── 02-mysql-secret.yaml
│   ├── 03-mysql-configmap.yaml
│   ├── 04-mysql-statefulset.yaml
│   ├── 05-backend-rbac.yaml
│   ├── 06-backend-configmap.yaml
│   ├── 07-backend-deployment.yaml
│   ├── 08-backend-hpa.yaml
│   ├── 09-backend-pdb.yaml
│   └── 10-ingress.yaml
├── deploy.sh                     # Automated deployment script
├── test-deployment.sh            # Testing script
└── DEPLOYMENT.md                 # This file
```

---

## 🚀 Prerequisites

1. **Minikube** installed
   ```bash
   brew install minikube  # macOS
   ```

2. **kubectl** installed
   ```bash
   brew install kubectl
   ```

3. **Docker** installed

---

## 📦 Deployment Steps

### Option 1: Automated Deployment

```bash
# Make script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

### Option 2: Manual Deployment

```bash
# 1. Start Minikube
minikube start --memory=4096 --cpus=2

# 2. Enable addons
minikube addons enable metrics-server
minikube addons enable ingress

# 3. Build and load image
docker build -t todoapp-backend:1.0.0 .
minikube image load todoapp-backend:1.0.0

# 4. Apply manifests
kubectl apply -f k8s/01-namespace.yaml
kubectl apply -f k8s/02-mysql-secret.yaml
kubectl apply -f k8s/03-mysql-configmap.yaml
kubectl apply -f k8s/04-mysql-statefulset.yaml

# Wait for MySQL
kubectl wait --for=condition=ready pod -l app=mysql -n todoapp --timeout=180s

kubectl apply -f k8s/05-backend-rbac.yaml
kubectl apply -f k8s/06-backend-configmap.yaml
kubectl apply -f k8s/07-backend-deployment.yaml
kubectl apply -f k8s/08-backend-hpa.yaml
kubectl apply -f k8s/09-backend-pdb.yaml
kubectl apply -f k8s/10-ingress.yaml

# 5. Add to /etc/hosts
echo "$(minikube ip) todoapp.local" | sudo tee -a /etc/hosts
```

---

## 🧪 Testing

```bash
chmod +x test-deployment.sh
./test-deployment.sh
```

Or manually:

```bash
# Check pods
kubectl get pods -n todoapp

# Test API
curl http://todoapp.local/items

# Check HPA
kubectl get hpa -n todoapp

# View logs
kubectl logs -f -l app=todoapp-backend -n todoapp

# Check metrics
kubectl top pods -n todoapp
```

---

## 📊 Monitoring

### Kubernetes Dashboard
```bash
minikube dashboard
```

### Watch Pods
```bash
kubectl get pods -n todoapp -w
```

### Describe HPA
```bash
kubectl describe hpa todoapp-backend-hpa -n todoapp
```

### View Events
```bash
kubectl get events -n todoapp --sort-by='.lastTimestamp'
```

---

## 🔧 Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name> -n todoapp
kubectl logs <pod-name> -n todoapp
```

### MySQL connection issues
```bash
# Check MySQL logs
kubectl logs mysql-0 -n todoapp

# Test connection
kubectl run mysql-client --image=mysql:8.0 --rm -it --restart=Never -n todoapp -- \
  mysql -h mysql.todoapp.svc.cluster.local -u root -p
```

### HPA not working
```bash
# Check metrics-server
kubectl get deployment metrics-server -n kube-system

# Check HPA status
kubectl describe hpa todoapp-backend-hpa -n todoapp
```

---

## 🔄 Updates and Rollbacks

### Update Image
```bash
# Build new version
docker build -t todoapp-backend:1.1.0 .
minikube image load todoapp-backend:1.1.0

# Update deployment
kubectl set image deployment/todoapp-backend backend=todoapp-backend:1.1.0 -n todoapp

# Watch rollout
kubectl rollout status deployment/todoapp-backend -n todoapp
```

### Rollback
```bash
# Check history
kubectl rollout history deployment/todoapp-backend -n todoapp

# Rollback
kubectl rollout undo deployment/todoapp-backend -n todoapp
```

---

## 🧹 Cleanup

```bash
# Delete namespace (deletes everything)
kubectl delete namespace todoapp

# Or delete individual resources
kubectl delete -f k8s/

# Stop Minikube
minikube stop

# Delete Minikube
minikube delete
```

---

## 🎯 Key Features Implemented

✅ **Namespace isolation** with ResourceQuota և LimitRange  
✅ **StatefulSet** MySQL-ի համար persistent data-ով  
✅ **Init Containers** database initialization-ի համար  
✅ **ConfigMaps և Secrets** configuration management-ի համար  
✅ **RBAC** security-ի համար  
✅ **Liveness, Readiness, Startup Probes** health checking-ի համար  
✅ **HPA** auto-scaling-ի համար  
✅ **PodDisruptionBudget** high availability-ի համար  
✅ **Rolling Updates** zero-downtime deployment-ի համար  
✅ **Sidecar Container** logging-ի համար  
✅ **Node Affinity & Pod Anti-Affinity** optimal placement-ի համար  
✅ **Ingress** external access-ի համար

---

## 📚 Best Practices Applied

- Multi-stage Docker builds
- Non-root containers
- Resource limits և requests
- Health checks (3 types)
- Graceful shutdown
- Zero-downtime deployments
- Auto-scaling based on metrics
- High availability configuration
- Security through RBAC
- Configuration separation (ConfigMaps/Secrets)

---

## 🤝 Contributing

For issues or improvements, please create a GitHub issue or pull request.

