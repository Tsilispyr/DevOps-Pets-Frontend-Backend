#!/bin/bash

echo "Setting up local Docker registry..."

# Start local Docker registry
docker run -d \
  --name docker-registry \
  --restart=always \
  -p 5000:5000 \
  -v registry-data:/var/lib/registry \
  registry:2

echo "Docker registry started on localhost:5000"

# Wait for registry to be ready
echo "Waiting for registry to be ready..."
sleep 5

# Test registry
echo "Testing registry..."
curl -s http://localhost:5000/v2/_catalog || echo "Registry not ready yet, will be available soon"

echo ""
echo "Docker registry setup complete!"
echo "Registry URL: localhost:5000"
echo "You can now push/pull images to/from this registry" 