📘 Saleor 3-Tier E-Commerce on AWS (Terraform + EKS + GitOps)
📌 Overview

이 프로젝트는 Saleor Headless E-Commerce 를
AWS 기반의 Production-Grade 3-Tier 아키텍처로 구성한 인프라 및 배포 시스템입니다.

전체 인프라는 Terraform → AWS
애플리케이션 배포는 GitHub Actions → ECR → ArgoCD → EKS
구조로 완전 자동화 되어 있습니다.

🏗️ Architecture
🔹 전체 구성도
Client(Web/App)
      │
Route53 Domain
      │
Amazon ALB (Ingress, internet-facing)
 ┌───────────────┼────────────────┬────────────────┐
 │                │                │                │
Storefront     Dashboard        API(Core)     /graphql route
(Next.js)      (React admin)    (Saleor)  
 │                │                │
 └─────────── Kubernetes(EKS) ───────────┘
                     │
          ┌──────────┴──────────┐
          │                     │
 Amazon RDS (PostgreSQL)   ElastiCache Redis
          │                     │
                Amazon S3 (media)


🚀 Features
✔ 1. 완전 자동화된 AWS 인프라 (Terraform)

- VPC, Subnet, NAT Gateway
- EKS Cluster
- RDS PostgreSQL
- ElastiCache Redis
- ECR Registry
- S3 Buckets (static/media)
- Security Group 자동 구성

✔ 2. GitOps 기반 배포 (ArgoCD + Kustomize)

- saleor-core / storefront / dashboard
- 환경변수, Deployment, Service, Ingress 관리
- 변경사항 commit → 자동 Sync

✔ 3. 도메인 + Ingress + ALB 자동 연동

- Route53 A 레코드
- ALB Ingress Controller/ → Storefront
- /graphql/ → Core API
- /dashboard → Saleor Dashboard

✔ 4. CI/CD 자동 빌드 (GitHub Actions)

- 각 앱의 Dockerfile 빌드
- ECR push
- ArgoCD 자동 배포 트리거

✔ 5. Production-Ready 구성을 위한 핵심 요소

- RDS Encryption + Backup
- Redis Auth + Encryption
- EKS Managed NodeGroup
- ALB Health Check
- Autoscaling 고려

📂 Repository Structure
saleor-3tier-infra/
└── terraform/
    ├── bootstrap/
    ├── envs/
    │   ├── dev/
    │   └── prod/
    └── modules/
        ├── vpc/
        ├── eks/
        ├── rds/
        ├── redis/
        ├── s3/
        └── ecr/

saleor-app-config/
└── apps/
    ├── saleor-core/
    ├── saleor-storefront/
    ├── saleor-dashboard/
    └── ingress/
