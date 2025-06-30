# MinIO Setup for Pet Adoption System

## Overview
MinIO is used as object storage for pet images in the Pet Adoption System.

## Configuration
- **API Port:** 9000
- **Console Port:** 9001
- **Username:** minioadmin
- **Password:** minioadmin123
- **Storage:** 5Gi persistent volume

## Deployment
```bash
kubectl apply -f k8s/minio/
```

## Access
- **API:** http://localhost:9000 (via port-forward)
- **Console:** http://localhost:9001 (via port-forward)

## Bucket Setup
1. Access MinIO console
2. Create bucket: `pets-images`
3. Set bucket policy for public read access

## Integration
The backend will use MinIO client to:
- Upload pet images
- Generate public URLs
- Store image metadata in database 