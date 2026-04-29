# Cloud RAG Infrastructure - LangFlow RAG Deployment on AWS

This project implements a RAG (Retrieval-Augmented Generation) application using LangFlow, deployed both locally with Docker Compose and in AWS EKS using Terraform. The application includes an Nginx reverse proxy for rate limiting and traffic management.

## Table of Contents

- [Project Description](#project-description)
- [Architecture](#architecture)
- [Components](#components)
- [Technologies Used](#technologies-used)
- [Local Deployment](#local-deployment)
- [AWS Deployment](#aws-deployment)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Usage](#usage)
- [Future Improvements](#future-improvements)
- [Important Notes](#important-notes)
- [License](#license)
- [Author](#author)

## Project Description

This project demonstrates a full deployment of an AI application (RAG with LangFlow) in cloud infrastructure using:

- Infrastructure as Code (IaC) with Terraform
- Container orchestration with Kubernetes (EKS)
- A multi-container application with service-to-service communication
- Remote state management in S3
- Automated and reproducible deployment

This is an ideal portfolio project to showcase skills in DevOps, Cloud Engineering, and production-style AI/ML application deployment.

## Architecture

The architecture image below represents the deployment topology used by this project:

![Architecture](architecture.png)

### Local Architecture (Docker Compose)

- `langflow` container exposed on port `7860`
- `postgres` container exposed on port `5432`
- `ambassador-nginx` container exposed on port `8080`
- Shared Docker Compose network for internal communication

### AWS Architecture (EKS)

- EKS cluster with namespace `grupo-2`
- Kubernetes deployment `proyecto-final` with one Pod and three containers:
  - `langflow` (`7860`)
  - `ambassador-nginx` (`8080`)
  - `postgres` (`5432`)
- Kubernetes Service `proyecto-final-service` of type `LoadBalancer`
- AWS Load Balancer automatically created by the Service

## Components

### 1. LangFlow

- Image: `langflowai/langflow:latest`
- Port: `7860`
- Function: Main RAG application that processes queries and generates responses using language models
- Database: Connects to PostgreSQL to store flow configuration and metadata

### 2. PostgreSQL

- Image: `postgres:16`
- Port: `5432`
- Function: Relational database used to store:
  - LangFlow configuration
  - Flow and component data
  - Application metadata

### 3. Ambassador Nginx

- Image: Built from `./nginx/Dockerfile` (deployed to ECR)
- Port: `8080`
- Function:
  - Reverse proxy with rate limiting (10 requests/minute)
  - Traffic management
  - Proxying to external services (Ngrok in current configuration)

## Technologies Used

### Development and Containers

- Docker - Application containerization
- Docker Compose - Local multi-container orchestration
- Nginx - Reverse proxy and rate limiting

### Cloud Infrastructure

- AWS EKS - Managed Kubernetes in AWS
- AWS S3 - Terraform state storage
- AWS ECR - Docker image registry
- AWS Load Balancer - Public service exposure

### Infrastructure as Code

- Terraform - Infrastructure provisioning and management
- Kubernetes Provider - Kubernetes resource management
- AWS Provider - AWS service integration

### Database

- PostgreSQL 16 - Relational database

### AI/ML

- LangFlow - Framework for building RAG workflows

## Local Deployment

### Prerequisites

- Docker installed
- Docker Compose installed

### Deployment Steps

1. Clone the repository (if applicable):

   ```bash
   git clone <repository-url>
   cd proyecto-final
   ```

2. Start Docker Compose:

   ```bash
   docker compose up
   ```

   Or detached:

   ```bash
   docker compose up -d
   ```

3. Access the services:
   - LangFlow: [http://localhost:7860](http://localhost:7860)
   - Ambassador Nginx: [http://localhost:8080](http://localhost:8080)
   - PostgreSQL: `localhost:5432`

4. View logs:

   ```bash
   docker compose logs -f
   ```

5. Stop services:

   ```bash
   docker compose down
   ```

### Volumes

The `docker-compose.yml` file creates two persistent volumes:

- `langflow-data`: Stores LangFlow configuration and data
- `langflow-postgres`: Stores PostgreSQL data

## AWS Deployment

### Prerequisites

- AWS CLI configured with valid credentials
- Terraform installed (version `>= 1.0`)
- `kubectl` installed and configured for the EKS cluster
- Access to an existing EKS cluster
- Required IAM permissions to:
  - Create resources in EKS
  - Access S3 for Terraform state
  - Retrieve EKS authentication tokens

### Initial Setup

1. Configure Terraform variables:

   Edit `infrastructure/terraform.tfvars` or provide environment variables:

   ```hcl
   aws_region                = "us-east-1"
   grupo                     = "grupo-2"
   kubernetes_cluster_name   = "master-dev-cluster"
   kubernetes_host           = "https://<your-eks-endpoint>.eks.us-east-1.amazonaws.com"
   kubernetes_ca_certificate = "<base64-encoded-ca-certificate>"
   ```

2. Initialize Terraform:

   ```bash
   cd infrastructure
   terraform init
   ```

3. Review the execution plan:

   ```bash
   terraform plan
   ```

4. Apply the configuration:

   ```bash
   terraform apply
   ```

   Confirm with `yes` when prompted.

### AWS Resources Created

#### 1. Kubernetes Namespace

- Name: `grupo-2` (configurable through variables)
- Purpose: Isolates project resources inside the cluster

#### 2. Kubernetes Deployment

- Name: `proyecto-final`
- Replicas: `1` (because PostgreSQL runs inside the same Pod)
- Containers:
  - `langflow`: Main application
  - `ambassador-nginx`: Reverse proxy
  - `postgres`: Database

#### 3. Kubernetes Service

- Name: `proyecto-final-service`
- Type: `LoadBalancer`
- Exposed ports:
  - Port `80` -> Target Port `7860` (LangFlow)

#### 4. AWS Load Balancer

- Automatically created by the Kubernetes Service of type `LoadBalancer`
- Provides a public endpoint to access the application

### Get the Service Endpoint

After applying Terraform, get the Load Balancer endpoint:

```bash
terraform output kubernetes_service_endpoint
```

Or with `kubectl`:

```bash
kubectl get service proyecto-final-service -n grupo-2
```

### Deployment Verification

1. Verify Pod status:

   ```bash
   kubectl get pods -n grupo-2
   ```

2. Check container logs:

   ```bash
   kubectl logs -n grupo-2 -l app=proyecto-final -c langflow
   kubectl logs -n grupo-2 -l app=proyecto-final -c ambassador-nginx
   kubectl logs -n grupo-2 -l app=proyecto-final -c postgres
   ```

3. Verify Service status:

   ```bash
   kubectl get service proyecto-final-service -n grupo-2
   ```

### Destroy Infrastructure

To remove all created resources:

```bash
cd infrastructure
terraform destroy
```

## Project Structure

```text
proyecto-final/
|
|-- infrastructure/              # Terraform configuration
|   |-- main.tf                  # Main resources (Deployment, Service)
|   |-- provider.tf              # Providers configuration (AWS, Kubernetes)
|   |-- variables.tf             # Variable definitions
|   |-- outputs.tf               # Terraform outputs
|   `-- terraform.tfvars         # Variable values (do not commit)
|
|-- nginx/                       # Nginx configuration
|   |-- Dockerfile               # Docker image for Ambassador Nginx
|   `-- nginx.conf               # Nginx config (rate limiting, proxy)
|
|-- docker-compose.yml           # Local orchestration
|-- README.md                    # This file
|
`-- [LangFlow JSON files]        # RAG flow configurations
    |-- Langflow Final.json
    |-- Langflow Final with OpenAI.json
    `-- ...
```

## Configuration

### LangFlow Environment Variables

- `LANGFLOW_DATABASE_URL`: PostgreSQL connection URL
  - Local: `postgresql://langflow:langflow@postgres:5432/langflow`
  - AWS: `postgresql://langflow:langflow@localhost:5432/langflow` (same Pod)
- `LANGFLOW_CONFIG_DIR`: Configuration directory (`app/langflow`)
- `AWS_DEFAULT_REGION`: AWS region (set through Terraform)

### Nginx Configuration

The `nginx/nginx.conf` file includes:

- Rate limiting: 10 requests/minute per IP
- Reverse proxy: routes traffic to external services
- Timeout configuration: tuned for long-running requests

### Terraform Remote State

Terraform state is stored in S3:

- Bucket: `terraform-state-ups-2025`
- Key: `terraform.tfstate.proyecto-final-grupo2`
- Region: `us-east-1`

The project also reads remote state from base infrastructure to retrieve:

- ECR repository URL for the Nginx image

## Usage

### Access LangFlow

1. Locally:
   - Open `http://localhost:7860`
   - Create or import RAG flows using the included JSON files

2. In AWS:
   - Get the Load Balancer endpoint with `terraform output`
   - Access the provided HTTP endpoint

### Import RAG Flows

The JSON files in the root directory contain LangFlow flow configurations you can import:

- `Langflow Final.json`
- `Langflow Final with OpenAI (no_key).json`

### Database Management

Locally:

```bash
docker compose exec postgres psql -U langflow -d langflow
```

In AWS:

```bash
kubectl exec -it -n grupo-2 <pod-name> -c postgres -- psql -U langflow -d langflow
```

## Future Improvements

### Infrastructure

- [ ] Implement PersistentVolumeClaims for PostgreSQL (instead of `empty_dir`)
- [ ] Separate PostgreSQL into an independent StatefulSet
- [ ] Add Horizontal Pod Autoscaler (HPA) for LangFlow
- [ ] Implement Kubernetes ConfigMaps and Secrets for sensitive config
- [ ] Add an Ingress Controller instead of direct LoadBalancer exposure
- [ ] Implement CI/CD pipeline (GitHub Actions, GitLab CI)

### Security

- [ ] Use AWS Secrets Manager for credentials
- [ ] Implement Network Policies to isolate traffic
- [ ] Add SSL/TLS certificates (`cert-manager`)
- [ ] Automatic database credential rotation

### Monitoring and Observability

- [ ] Integrate CloudWatch for logs and metrics
- [ ] Implement Prometheus and Grafana
- [ ] Add health checks and readiness probes
- [ ] Build an application monitoring dashboard

### Scalability

- [ ] Configure multiple LangFlow replicas (without PostgreSQL in the same Pod)
- [ ] Implement Redis for caching
- [ ] Optimize database connection pooling
- [ ] Add a CDN for static assets

### Development

- [ ] Add automated tests
- [ ] API documentation
- [ ] Docker image versioning
- [ ] Blue/Green deployments

## Important Notes

### Production Considerations

Warning: The current deployment has production limitations:

1. Data persistence: `empty_dir` volumes are ephemeral. Data is lost if the Pod restarts.
2. Security: Credentials are hardcoded. Use Secrets Manager in production.
3. Scalability: PostgreSQL in the same Pod limits horizontal scaling.
4. Backup: No database backup strategy is currently implemented.

### Troubleshooting

Error: `ExpiredTokenException`

- AWS credentials have expired. Renew your credentials or session token.

Error: `Connection refused` when connecting to Kubernetes

- Verify `kubectl` is configured correctly for your EKS cluster.
- Confirm `kubernetes_host` and `kubernetes_ca_certificate` values are correct.

Pods in `CrashLoopBackOff` state

- Check logs: `kubectl logs -n grupo-2 <pod-name>`
- Verify Docker images are available and accessible.

