# 🚢 Shipyard App

A end-to-end DevOps project demonstrating a real-world deployment 
pipeline — from local development to cloud infrastructure.

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| App | Node.js (HTTP API) |
| Containerization | Docker |
| CI/CD | GitHub Actions |
| Container Registry | AWS ECR |
| Infrastructure | Terraform |
| Cloud | AWS (VPC, EC2, Security Groups) |
| Monitoring | AWS CloudWatch |

## 🔄 Pipeline Flow
Code Push → GitHub Actions → Docker Build → ECR Push → EC2 Deploy

## 📁 Project Structure
shipyard-app/
├── app.js                    # Node.js API with /health endpoint
├── Dockerfile                # Multi-layer optimized image
├── package.json
├── cloudwatch_check.py       # boto3 monitoring script
├── .github/
│   └── workflows/
│       └── deploy.yml        # CI/CD pipeline
└── terraform/
├── main.tf               # VPC, EC2, Security Groups
├── variables.tf
└── outputs.tf

## 🚀 What This Project Covers

**Docker**
- Optimized Dockerfile with alpine base image
- Layer caching for faster builds
- Environment-specific configuration via ENV variables
- `/health` endpoint for container health checks

**GitHub Actions CI/CD**
- Automated Docker image build on every push to `main`
- AWS ECR authentication via GitHub Secrets
- Image tagged with git commit SHA for traceability
- Separate build vs deploy stages

**Terraform — Infrastructure as Code**
- VPC with public subnet
- Internet Gateway + Route Table (full internet connectivity)
- Security Groups (port 22 + app port)
- EC2 instance with user_data bootstrap script
- Modular, reusable configuration

**AWS**
- ECR — private Docker image registry
- EC2 — application hosting
- CloudWatch — CPU alarms + monitoring
- IAM — least privilege access

## 🐛 Real Debugging Experience

- **CMD vs COPY** — Dockerfile syntax issue causing container to exit immediately; identified via `docker logs` and fixed
- **Route Table missing IGW route** — EC2 SSH timeout; debugged via `ssh -v` and AWS CLI route table inspection; fixed by adding `aws_route` resource in Terraform
- **SSH user mismatch** — `ec2-user` vs `ubuntu` for different AMIs

## 📊 Monitoring

CloudWatch alarm configured:
- **Metric:** CPUUtilization
- **Threshold:** > 80% for 2 consecutive periods  
- **Action:** SNS email notification

## 🔐 Security Practices

- AWS credentials stored as GitHub Secrets — never hardcoded
- Security Groups follow least privilege — only required ports open
- `.dockerignore` prevents sensitive files from entering image

## 💡 Key Learnings

- End-to-end ownership — from Dockerfile to cloud infrastructure
- Real debugging in cloud environments
- Infrastructure as Code benefits — reproducible, version-controlled
- CI/CD automation reduces manual errors

### 🛠️ Prerequisites & CI/CD Setup

If you fork this repository and want to run the deployment pipeline, you need to configure a few GitHub Secrets for your workflow to succeed.

1. Go to your forked repository's **Settings > Secrets and variables > Actions**.
2. Click **New repository secret** and add the following:
   * `TF_VAR_PUBLIC_KEY`: The contents of your public SSH key (`~/.ssh/id_rsa.pub`).
   * `TF_VAR_MY_IP`: Your current local public IP address with a `/32` CIDR suffix (e.g., `192.0.2.1/32`). 
     * *Note: You can find your current public IP by searching "What is my IP" on Google or running `curl ifconfig.me` in your terminal. Because home IPs are usually dynamic, you may need to update this secret if your ISP changes your IP.*
