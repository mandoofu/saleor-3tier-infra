# Saleor 3‑Tier on AWS (EKS + RDS + Redis + S3 + GitOps)

> **목표**  
> 오픈소스 이커머스 플랫폼 **Saleor**를 AWS 상에서 **3‑Tier 아키텍처 + GitOps + CI/CD** 구조로 안정적으로 운영하기 위한 인프라 구축 프로젝트입니다.  
> IaC(Terraform)·EKS·ArgoCD·GitHub Actions 기반으로 실서비스 수준 구조를 포트폴리오 형태로 구성했습니다.

---

## 1. 전체 프로젝트 구성

이 프로젝트는 총 5개의 GitHub 리포지토리로 구성됩니다.

| 리포지토리 | 역할 |
|-----------|------|
| **saleor-3tier-infra** | Terraform 인프라 (VPC, EKS, RDS, Redis, S3, ECR) |
| **saleor-app-config** | Kustomize + Argo CD GitOps 구성 |
| **saleor-core** | Django + GraphQL API (Backend) |
| **saleor-storefront** | Next.js Storefront (고객용 페이지) |
| **saleor-dashboard** | React 기반 관리자 Dashboard |

---

## 2. 아키텍처 개요

### 2‑1. 전체 서비스 아키텍처

프로젝트에 맞게 재구성한 다이어그램을 아래와 같이 사용합니다.

```
docs/images/saleor-3tier-eks-architecture.png
```

> AWS 공식 아키텍처 예시를 참고하여 프로젝트 구조에 맞게 직접 재작성한 이미지입니다.  
> 공식 이미지 사용 시 README에는 링크/출처만 명시하는 것을 권장합니다.

### 주요 구성 요소

- **Route 53**
  - `u3-store.msp-g1.click` → ALB
  - `u3-admin.msp-g1.click` → ALB

- **ALB (AWS Load Balancer Controller + Ingress)**
  - Storefront / Dashboard 트래픽 분기

- **EKS**
  - Namespaces: `backend`, `frontend`
  - Deployments:
    - `saleor-core` (포트 8000)
    - `saleor-storefront` (포트 3000 → Service 80)
    - `saleor-dashboard` (포트 80)

- **RDS (PostgreSQL 15)**
  - DB 연결 정보는 Secret/ConfigMap으로 관리

- **Redis (ElastiCache)**
  - 세션/캐시/작업 큐 용도

- **S3**
  - 미디어 업로드 저장 버킷

- **ECR**
  - Core / Storefront / Dashboard 이미지 저장

---

## 3. CI/CD & GitOps 구조

```
docs/images/saleor-3tier-ci-cd.png
```

### 전체 흐름

1. **GitHub Actions**
   - 각 애플리케이션 리포에서 Docker 이미지 빌드 후 ECR로 Push
2. **saleor-app-config (Kustomize)**
   - 이미지 태그 자동 업데이트
3. **Argo CD**
   - Git 상태를 EKS로 자동 반영(Sync)
   - Application of Applications 구조로 dev/prod 환경 분리

---

## 4. Terraform 구성

### 4‑1. Backend (S3 + DynamoDB Lock)

```hcl
terraform {
  backend "s3" {
    bucket         = "saleor-store-251204"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-3"
    dynamodb_table = "tf-state-lock"
    encrypt        = true
  }
}
```

### 4‑2. 주요 모듈

- vpc  
- eks  
- rds  
- redis  
- s3  
- ecr  

각 리소스는 재사용 가능한 Terraform AWS 공식 모듈 기반으로 구성함.

---

## 5. GitOps 디렉터리 구조 (saleor-app-config)

```
saleor-app-config/
├─ base/
│  ├─ namespaces.yaml
│  ├─ saleor-core/
│  ├─ saleor-storefront/
│  ├─ saleor-dashboard/
│  └─ ingress/
└─ overlays/
   ├─ dev/
   └─ prod/
```

Ingress 라우팅:

- `u3-store.msp-g1.click` → `saleor-storefront`
- `u3-admin.msp-g1.click` → `saleor-dashboard`

---

## 6. 인프라 및 앱 배포 플로우

### 6‑1. 인프라 배포

```bash
cd envs/dev
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### 6‑2. 애플리케이션 배포

```bash
aws eks update-kubeconfig   --name saleor-3tier-dev-eks   --region ap-northeast-3
```

Argo CD에서 다음 순서로 Sync:

1. saleor-core  
2. saleor-storefront  
3. saleor-dashboard  
4. ingress

---
