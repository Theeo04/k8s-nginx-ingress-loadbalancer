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

## Performance Optimizations

The cluster is optimized for performance and reliability:

### 1. Ingress Controller Tuning
- Optimized proxy timeouts and buffer sizes
- GZIP compression for faster content delivery
- Modern SSL ciphers for security and performance
- Efficient proxy buffering configuration

### 2. Deployment Optimizations
- Pod anti-affinity for high availability
- Zero-downtime rolling updates
- Resource limits and requests
- Optimized health check probes
- Pod distribution across nodes

### 3. NGINX Performance Tuning
- Connection keepalive optimization
- Buffer size tuning
- GZIP compression
- File handle caching
- Client buffer optimizations

### 4. Monitoring and Health
- Resource usage monitoring via `kubectl top`
- Health check endpoints
- Readiness/Liveness probes
- Performance metrics collection

To monitor cluster performance:
```bash
# View pod resource usage
kubectl top pods

# Check pod distribution
kubectl get pods -o wide

# View detailed pod information
kubectl describe pods
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

#### Security Layer (TLS/HTTPS)

The application is secured using TLS/HTTPS:

- **TLS Configuration**:
  - Self-signed certificate for `webserver.local`
  - Stored in Kubernetes Secret `webserver-tls`
  - Automatic HTTP to HTTPS redirection
  - HTTP Strict Transport Security (HSTS) enabled

- **Security Features**:
  - TLSv1.3 protocol
  - Modern cipher suites
  - Force SSL redirect
  - HTTP/2 support for better performance

To test locally:
1. Add to `/etc/hosts`:
   ```
   127.0.0.1 webserver.local
   ```
2. Access via HTTPS:
   ```bash
   curl -k https://webserver.local:8443
   ```

Note: In production, replace the self-signed certificate with a valid certificate from a trusted CA.

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

# Kubernetes NGINX Ingress with TLS and Load Balancing

A production-ready Kubernetes setup demonstrating NGINX Ingress Controller with TLS termination, load balancing, and high availability.

## Architecture Overview

```
Client Request → NGINX Ingress → Service → Pods (3 replicas)
    (HTTPS)     (TLS/LoadBalancer)  (ClusterIP)  (Web Servers)
```

## Features

- Load Balancing (Service & Ingress levels)
- TLS/HTTPS with automatic redirection
- High Availability (3 replicas)
- Performance optimizations
- Health monitoring
- Zero-downtime deployments

## Components

### 1. Web Server Deployment
- 3 NGINX pod replicas
- Resource limits and requests
- Health checks (readiness/liveness)
- Pod anti-affinity for HA
- Rolling update strategy

### 2. Service Layer
- Type: ClusterIP
- Internal load balancing
- Pod health tracking
- Automatic endpoint updates

### 3. Ingress Controller
- TLS termination
- HTTP → HTTPS redirect
- Advanced routing
- Performance tuning
- GZIP compression

### 4. Security Layer
- TLSv1.3 protocol
- Modern cipher suites
- HSTS enabled
- HTTP/2 support

## Performance Optimizations

### NGINX Configuration
- Connection keepalive
- Buffer size tuning
- GZIP compression
- File handle caching
- Client buffer optimizations

### Kubernetes Tuning
- Pod anti-affinity
- Resource management
- Zero-downtime updates
- Health probe optimization
- Load distribution

## Installation

1. Deploy NGINX Ingress Controller:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

2. Create TLS certificate:
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=webserver.local"
```

3. Create Kubernetes Secret:
```bash
kubectl create secret tls webserver-tls --key tls.key --cert tls.crt
```

4. Deploy the application:
```bash
kubectl apply -f nginx-config.yaml
kubectl apply -f webserver-deployment.yaml
kubectl apply -f webserver-service.yaml
kubectl apply -f ingress.yaml
```

## Configuration Files

### nginx-config.yaml
- NGINX server configuration
- Performance optimizations
- Health check endpoint
- Custom HTML response

### webserver-deployment.yaml
- Pod specifications
- Resource limits
- Health probes
- Volume mounts
- Update strategy

### ingress.yaml
- TLS configuration
- Routing rules
- Performance annotations
- Security headers

## Testing

1. Add to `/etc/hosts`:
```
127.0.0.1 webserver.local
```

2. Test HTTPS:
```bash
curl -k https://webserver.local:8443
```

3. Verify HTTP redirect:
```bash
curl -L http://webserver.local:8080
```

4. Check health endpoint:
```bash
curl -k https://webserver.local:8443/health
```

## Monitoring

### Resource Usage
```bash
# Pod resource consumption
kubectl top pods

# Pod distribution
kubectl get pods -o wide
```

### Health Checks
```bash
# Pod status
kubectl get pods

# Detailed pod info
kubectl describe pods
```

### Logs
```bash
# Ingress controller logs
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller

# Web server logs
kubectl logs -l app=webserver
```

## Troubleshooting

### Common Issues

1. Pod Startup Issues
- Check volume mounts
- Verify ConfigMap keys
- Review resource limits
- Check health probe settings

2. TLS Issues
- Verify secret exists
- Check certificate validity
- Confirm Ingress TLS config
- Review HTTPS redirect settings

3. Load Balancing Issues
- Check service endpoints
- Verify pod readiness
- Review anti-affinity rules
- Check node distribution

## Security Considerations

1. TLS Configuration
- Modern protocols (TLSv1.2, TLSv1.3)
- Secure cipher suites
- HSTS enabled
- Automatic HTTPS redirect

2. Resource Protection
- Memory limits
- CPU constraints
- Network policies
- Health monitoring

## Production Readiness

Before deploying to production:
1. Replace self-signed certificate with valid SSL
2. Adjust resource limits based on load
3. Configure proper monitoring
4. Set up logging aggregation
5. Implement backup strategy

## Maintenance

### Updates
- Use rolling updates
- Monitor pod health
- Check resource usage
- Review logs regularly

### Scaling
- Adjust replica count
- Monitor resource usage
- Update resource limits
- Check node capacity
