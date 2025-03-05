#!/bin/bash

PORT=8443
NUM_REQUESTS=10

echo "Testing Ingress load balancing..."
echo "Making $NUM_REQUESTS parallel requests to see which pods handle them..."
echo

# Kill any existing port-forward
pkill -f "port-forward" || true

# Start port-forward to ingress controller
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller $PORT:443 &
sleep 2  # Wait for port-forward to establish

# Function to make a request
make_request() {
    local id=$1
    echo -n "Request $id: "
    curl -s http://localhost:$PORT | grep -o 'Pod: webserver-deployment.*</div>' | sed 's/<\/div>//'
}

# Make parallel requests
for i in $(seq 1 $NUM_REQUESTS); do
    make_request $i &
done

# Wait for all requests to complete
wait

# Clean up port-forward
pkill -f "port-forward"

echo -e "\nDone! Check the pod names above to verify load balancing."
