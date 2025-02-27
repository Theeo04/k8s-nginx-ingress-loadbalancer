# Kubernetes Load Balancer Demo

This project demonstrates a production-like Kubernetes pod level load balancing (ClusterIP) setup using NGINX Ingress Controller. It shows how to distribute traffic across multiple web server pods while maintaining high availability and scalability.

## Architecture Overview

```
External Request
      ↓
NGINX Ingress Controller (LoadBalancer)
      ↓
Ingress Rules (routing configuration)
      ↓
Internal Service (ClusterIP)
      ↓
Web Server Pods (3 replicas)
```

## Components

### 1. NGINX Ingress Controller
- Acts as the main entry point for external traffic
- Handles traffic routing and load balancing
- Runs as a LoadBalancer service

### 2. Web Server Deployment
- Runs 3 replicas of NGINX pods
- Each pod displays its unique identifier
- Includes resource limits and health checks
- Uses custom NGINX configuration

### 3. Internal Service
- Type: ClusterIP (internal only)
- Load balances traffic between pods
- Provides stable internal endpoint

### 4. Ingress Resource
- Defines routing rules
- Maps external requests to internal service
- Configures SSL/TLS (if needed)

## Configuration Files

### 1. webserver-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webserver-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webserver
  template:
    metadata:
      labels:
        app: webserver
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
```

### 2. webserver-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: webserver-service
spec:
  type: ClusterIP
  selector:
    app: webserver
  ports:
  - port: 80
```

### 3. ingress.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webserver-ingress
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webserver-service
            port:
              number: 80
```

## Setup Instructions

1. Install NGINX Ingress Controller:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

2. Apply configurations:
```bash
kubectl apply -f nginx-config.yaml
kubectl apply -f webserver-deployment.yaml
kubectl apply -f webserver-service.yaml
kubectl apply -f ingress.yaml
```

3. Wait for all components to be ready:
```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

## Accessing the Service

### Local Development
For local development, use port-forward:
```bash
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80
```
Then access: http://localhost:8080

### Production Environment
In a production environment:
1. The Ingress Controller gets a real external IP
2. Configure DNS to point to this IP
3. Access through your domain name

## Testing Load Balancing

Use the provided test script:
```bash
./test-ingress.sh
```

This script:
1. Sets up port forwarding
2. Makes multiple parallel requests
3. Shows which pods handle each request
4. Demonstrates load distribution

## Load Balancing Behavior

The system performs load balancing at two levels:
1. **Ingress Controller Level**
   - Distributes incoming external traffic
   - Handles SSL termination
   - Manages routing rules

2. **Service Level**
   - Distributes traffic among pods
   - Provides internal load balancing
   - Handles pod failures automatically

## Monitoring and Verification

1. Check pod status:
```bash
kubectl get pods -l app=webserver
```

2. Check service status:
```bash
kubectl get svc webserver-service
```

3. Check ingress status:
```bash
kubectl get ingress
kubectl get svc -n ingress-nginx
```

## Troubleshooting

1. If pods aren't receiving traffic:
   - Check pod readiness: `kubectl get pods`
   - Verify service selector: `kubectl describe svc webserver-service`
   - Check ingress configuration: `kubectl describe ingress webserver-ingress`

2. If Ingress Controller isn't accessible:
   - Check controller pods: `kubectl get pods -n ingress-nginx`
   - Verify service: `kubectl get svc -n ingress-nginx`
   - Check logs: `kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller`

## Security Considerations

1. The setup includes:
   - Resource limits on pods
   - Health checks
   - Readiness probes
   - Clean separation of concerns

2. Additional security measures to consider:
   - Enable SSL/TLS
   - Add authentication
   - Implement network policies
   - Configure rate limiting

## Maintenance

1. Scaling:
   ```bash
   kubectl scale deployment/webserver-deployment --replicas=5
   ```

2. Updating configuration:
   ```bash
   kubectl apply -f nginx-config.yaml
   ```

3. Rolling updates:
   ```bash
   kubectl set image deployment/webserver-deployment nginx=nginx:1.25.1
   ```

## Best Practices

1. Always use resource limits
2. Implement health checks
3. Use rolling updates
4. Monitor pod health
5. Keep configurations in version control
6. Use namespaces for isolation
7. Implement proper logging and monitoring
