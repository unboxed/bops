# BOPS Infrastructure Architecture

This document describes the BOPS (Back-Office Planning System) infrastructure architecture, reverse-engineered from the `bops` (Rails application) and `bops-terraform` (infrastructure-as-code) repositories.

## Important Caveats

- **Versions cited are from repository source files as of February 2026**, not verified against live infrastructure. Actual deployed versions may differ. Always verify against live AWS resources and `Gemfile.lock`.
- **Terraform defaults vs overrides**: Many module variables have defaults. Production may override these via `terraform.tfvars`, CLI variables, or post-apply manual changes not reflected in source.
- **This analysis is static code analysis only**. Infrastructure may have been modified outside of Terraform.
- **Resource counts** (e.g., "2 tasks", "2 cache clusters") reflect Terraform source defaults. Auto-scaling or manual scaling may result in different actual counts.
- Items marked **[ASSUMPTION]** should be confirmed against live infrastructure.

---

## A) Architecture Diagrams

### A1) System Context

```
                                ┌───────────────────────────┐
  Planning Officer ────────────►│                           ├───────► GOV.UK Notify
    HTTPS (council subdomain)   │                           │           (Email/SMS)
                                │                           │
  Applicant ───────────────────►│                           ├───────► Ordnance Survey
    HTTPS (applicants subdomain)│                           │           APIs
                                │           BOPS            │
  Consultee ───────────────────►│                           ├───────► PAAPI
    HTTPS                       │    Rails 8.0 multi-tenant │           (Planning Data)
                                │    app with 11 engines    │
  Neighbour ───────────────────►│                           ├───────► AppSignal (APM)
    HTTPS                       │    Subdomain per LA       │
                                │    e.g. southwark         │
  LA Admin ────────────────────►│         .bops.services    ├───────► Slack
    HTTPS (council subdomain    │                           │           (via Chatbot)
     /admin path)               │                           │
                                │                           │
  Global Admin ────────────────►│                           │
    HTTPS (config subdomain)    │                           │
                                │                           │
  PlanX ───────────────────────►│                           │
    HTTPS REST API              │                           │
                                └───────────────────────────┘
```

**User access patterns:**

| User             | Subdomain                            | Engine          |
|------------------|--------------------------------------|-----------------|
| Planning Officer | `{council}.bops.services`            | bops_admin      |
| Applicant        | `{council}.applicants.bops.services` | bops_applicants |
| Consultee        | `{council}.bops.services/consultees` | bops_consultees |
| Neighbour        | `{council}.applicants.bops.services` | bops_applicants |
| LA Admin         | `{council}.bops.services/admin`      | bops_admin      |
| Global Admin     | `config.bops.services`               | bops_config     |
| PlanX (API)      | `{council}.bops.services/api`        | bops_api        |

### A2) Infrastructure Overview

```
                              ┌─────────────────────────────┐
                              │         Internet            │
                              │   Users / API Clients       │
                              └─────────────┬───────────────┘
                                            │ HTTPS
                                            ▼
                              ┌─────────────────────────────┐
                              │       Route53 (DNS)         │
                              │  *.bops.services            │
                              │  *.applicants.bops.services │
                              └─────────────┬───────────────┘
                                            │
                              ┌─────────────▼───────────────┐
                              │     CloudFront (CDN)        │
                              │                             │
                              │  ┌────────┐ ┌────────────┐  │
                              │  │  WAF   │ │ TLS 1.2+   │  │
                              │  └────────┘ └────────────┘  │
                              └──┬──────────┬───────────┬───┘
                                 │          │           │
                      Dynamic    │          │ /assets/* │  /blobs/*
                      requests   │          │           │  (signed URLs)
                                 │          │           │
                                 ▼          ▼           ▼
┌────────────────────────────────────┐  ┌───────┐  ┌───────────┐
│                                    │  │  S3   │  │    S3     │
│    Application Load Balancer       │  │Assets │  │  Uploads  │
│    (host-based routing,            │  │Bucket │  │  Bucket   │
│     blue/green target groups)      │  └───────┘  └───────────┘
│                                    │
└──────────────────┬─────────────────┘
                   │ :3000
                   ▼
┌──────────────────────────────────────────────────────────┐
│                  ECS Cluster (Fargate)                   │
│                                                          │
│  ┌──────────────────┐  ┌─────────────────┐  ┌─────────┐  │
│  │   Web Service    │  │ Worker Service  │  │ Console │  │
│  │                  │  │                 │  │ Service │  │
│  │  Rails 8 / Puma  │  │    Sidekiq      │  │         │  │
│  │  2 tasks         │  │    2 tasks      │  │ 1 task  │  │
│  │  512 CPU         │  │    512 CPU      │  │ ECS     │  │
│  │  2048 MiB        │  │    2048 MiB     │  │ Exec    │  │
│  │                  │  │                 │  │         │  │
│  │  CodeDeploy      │  │                 │  │         │  │
│  │  blue/green      │  │                 │  │         │  │
│  └────────┬─────────┘  └───────┬─────────┘  └─────────┘  │
│           │                    │                         │
└───────────┼────────────────────┼─────────────────────────┘
            │                    │
            ▼                    ▼
   ┌─────────────────┐  ┌──────────────────────┐
   │   PostgreSQL    │  │   Redis              │
   │   + PostGIS     │  │   (ElastiCache)      │
   │                 │  │                      │
   │   AWS RDS       │  │   Sidekiq queue      │
   │   Encrypted     │  │   backend            │
   │   Performance   │  │   Multi-AZ           │
   │   Insights      │  │   2 cache clusters   │
   └─────────────────┘  └──────────────────────┘

   Both Web and Worker connect to both
   PostgreSQL (data) and Redis (job queue).
```

### A3) Request Flow

```
  Officer                CloudFront        ALB           Web (Puma)            DB
    │                        │              │                │                  │
    │── southwark.bops.services ──────────► │                │                  │
    │                        │── forward ──►│                │                  │
    │                        │              │── :3000 ──────►│                  │
    │                        │              │                │                  │
    │                        │              │                │── Middleware:    │
    │                        │              │                │   extract        │
    │                        │              │                │   "southwark"    │
    │                        │              │                │   from subdomain │
    │                        │              │                │                  │
    │                        │              │                │── session ──────►│
    │                        │              │                │   lookup         │
    │                        │              │                │                  │
    │                        │              │                │── query ────────►│
    │                        │              │                │   planning_apps  │
    │                        │              │                │   (scoped to LA) │
    │                        │              │                │                  │
    │◄─────────────────── HTML response ──────────────────── │                  │
    │                        │              │                │                  │
```

### A4) Background Job Flow

```
  Web (Puma)          Redis              Worker (Sidekiq)       DB            GOV.UK Notify
    │                   │                      │                │                  │
    │── enqueue job ──► │                      │                │                  │
    │                   │                      │                │                  │
    │                   │   Queues:            │                │                  │
    │                   │   - high_priority    │                │                  │
    │                   │   - low_priority     │                │                  │
    │                   │   - submissions      │                │                  │
    │                   │                      │                │                  │
    │                   │◄── dequeue job ──────│                │                  │
    │                   │                      │── load ───────►│                  │
    │                   │                      │   records      │                  │
    │                   │                      │                │                  │
    │                   │                      │── send email ──────────────────►  │
    │                   │                      │                │                  │
    │                   │                      │◄───── delivery confirmation ────  │
    │                   │                      │                │                  │
```

### A5) File Upload & Serving

```
  Browser             CloudFront         Web (Rails)        S3 Uploads
    │                     │                  │                   │
    │── POST upload ─────►│                  │                   │
    │                     │── forward ──────►│                   │
    │                     │                  │── PutObject ─────►│
    │                     │                  │◄── confirmed ─────│
    │◄──── upload success ────────────────── │                   │
    │                     │                  │                   │
    │                     │                  │                   │
    │   Later: file access                   │                   │
    │                     │                  │                   │
    │── GET /blobs/{id} ─►│                  │                   │
    │                     │── strip /blobs/ prefix               │
    │                     │── validate signed URL                │
    │                     │── GetObject ────────────────────────►│
    │                     │◄─── file content ─────────────────── │
    │◄──── file served ───│                  │                   │
    │                     │                  │                   │
```

### A6) CI/CD Pipeline

```
  GitHub Actions         ECR              S3 Assets        ECS / CodeDeploy
    │                     │                  │                   │
    │── build Docker      │                  │                   │
    │   image             │                  │                   │
    │── push ───────────► │                  │                   │
    │   (tagged by        │                  │                   │
    │    git SHA)         │                  │                   │
    │                     │                  │                   │
    │── sync precompiled ────────────────►   │                   │
    │   assets            │                  │                   │
    │                     │                  │                   │
    │── deploy ──────────────────────────────────────────────►   │
    │   (blue/green)      │                  │                   │
    │                     │                  │                   │
    │   Console: update task definition                          │
    │   Worker:  update task definition                          │
    │   Web:     CodeDeploy blue/green swap                      │
    │                     │                  │                   │
    │                     │              SNS ──► Slack           │
    │                     │              (deploy notification)   │
    │                     │                  │                   │
```

### A7) Monitoring & Notifications

```
  ┌──────────────────────────────────────────────────────────┐
  │                  AWS Monitoring                          │
  │                                                          │
  │  ┌──────────────────┐  ┌───────────────────┐             │
  │  │ CloudWatch Logs  │  │  AWS Security Hub │             │
  │  │                  │  │                   │             │
  │  │  web (30d)       │  │  HIGH/CRITICAL    │──┐          │
  │  │  worker (30d)    │  │  findings         │  │          │
  │  │  console (30d)   │  └───────────────────┘  │          │
  │  └──────────────────┘                         │   SNS    │
  │                                               │  Topics  │
  │  ┌──────────────────┐  ┌───────────────────┐  │          │
  │  │ AWS Config       │  │  RDS Events       │──┤          │
  │  │ Recorder         │──│  AWS Health       │──┤          │
  │  │ (all resources)  │  │  Deploy Events    │──┤          │
  │  └──────────────────┘  └───────────────────┘  │          │
  │                                               │          │
  │                                  ┌────────────▼──────┐   │
  │                                  │   AWS Chatbot     │   │
  │                                  │                   │   │
  │                                  │   ──► Slack       │   │
  │                                  └───────────────────┘   │
  └──────────────────────────────────────────────────────────┘
```

---

## B) Architecture Inventory

### B1) Component Inventory

| Component | Type | Purpose | Tech | Defined In |
|---|---|---|---|---|
| **CloudFront Distribution** | CDN | TLS termination, caching, WAF | AWS CloudFront | `bops-terraform/modules/ecs_bops/cloudfront.tf` |
| **ALB** | Load Balancer | Host-based routing, HTTP→HTTPS redirect | AWS ALB | `bops-terraform/modules/load_balancer/main.tf` |
| **Target Groups (Blue/Green)** | LB Target | Blue/green deployment targets | AWS ALB Target Group | `bops-terraform/modules/ecs_bops/load_balancer.tf` |
| **ECS Cluster** | Container Platform | Runs all Fargate tasks | AWS ECS | `bops-terraform/modules/ecs_cluster/main.tf` |
| **Web Service** | Application | Rails 8 web server (Puma) | ECS Fargate, 2 tasks | `bops-terraform/modules/ecs_bops/ecs.tf` |
| **Worker Service** | Background Jobs | Sidekiq job processor | ECS Fargate, 2 tasks | `bops-terraform/modules/ecs_bops/ecs.tf` |
| **Console Service** | Management | Interactive console access | ECS Fargate, 1 task, ECS Exec | `bops-terraform/modules/ecs_bops/ecs.tf` |
| **RDS Primary** | Database | Application data store | PostgreSQL + PostGIS on RDS | `bops-terraform/modules/database/main.tf` |
| **ElastiCache Redis** | Cache/Queue | Sidekiq queue backend | Redis, multi-AZ, 2 clusters | `bops-terraform/modules/redis/main.tf` |
| **S3 Uploads** | Object Storage | Active Storage file uploads | AWS S3 | `bops-terraform/modules/ecs_bops/s3.tf` |
| **S3 Assets** | Object Storage | Precompiled static assets | AWS S3 | `bops-terraform/modules/ecs_bops/assets.tf` |
| **S3 Import** | Object Storage | Bulk data imports | AWS S3, versioned | `bops-terraform/modules/ecs_bops/s3.tf` |
| **ECR Repository** | Container Registry | Docker image storage | AWS ECR | `bops-terraform/modules/ecs_bops/ecs.tf` |
| **CodeDeploy** | Deployment | Blue/green deployments | AWS CodeDeploy | `bops-terraform/modules/ecs_bops/codedeploy.tf` |
| **Route53** | DNS | Domain management | AWS Route53 | `bops-terraform/modules/ecs_bops/cloudfront.tf` |
| **SSM Parameter Store** | Secrets | Application secrets | AWS SSM SecureString | `bops-terraform/modules/database/main.tf` |
| **AWS Chatbot** | Notifications | SNS → Slack forwarding | AWS Chatbot | `bops-terraform/slack/main.tf` |
| **GitHub Actions** | CI/CD | Build, test, deploy | GitHub Actions + OIDC | `bops/.github/workflows/deploy-environment.yml` |

### B1.1) Rails Engine Inventory

| Engine | Mount Path | Purpose | Defined In |
|---|---|---|---|
| **bops_core** | (shared) | Routing helpers, middleware, base controllers | `engines/bops_core/` |
| **bops_admin** | `/admin` | LA admin: users, app types, consultees, policy | `engines/bops_admin/` |
| **bops_api** | `/api` | Public/authenticated REST API, Swagger docs | `engines/bops_api/` |
| **bops_applicants** | `/` (applicants subdomain) | Applicant responses, neighbour comments | `engines/bops_applicants/` |
| **bops_config** | `/` (config subdomain) | Global config, Sidekiq UI | `engines/bops_config/` |
| **bops_consultees** | `/consultees` | External consultee view/comment | `engines/bops_consultees/` |
| **bops_enforcements** | `/` | Enforcement case management | `engines/bops_enforcements/` |
| **bops_preapps** | `/preapps` | Pre-application advice workflow | `engines/bops_preapps/` |
| **bops_reports** | `/reports` | Report generation | `engines/bops_reports/` |
| **bops_submissions** | `/api` (submissions) | Incoming application submission handling | `engines/bops_submissions/` |
| **bops_uploads** | (uploads subdomain) | File uploads via Active Storage | `engines/bops_uploads/` |

### B2) Data Stores

**Note:** Versions below are from Terraform source files. Actual deployed versions may differ — RDS and ElastiCache can be upgraded independently of Terraform. Verify against live AWS resources.

| Store | Data Type | Retention | Defined In |
|---|---|---|---|
| **RDS PostgreSQL + PostGIS** | Planning applications, users, local authorities, consultations, decisions, addresses, geodata | 7-day backup | `bops-terraform/modules/database/main.tf` |
| **ElastiCache Redis** | Sidekiq job queue data (transient) | Transient | `bops-terraform/modules/redis/main.tf` |
| **S3 Uploads** | Uploaded documents (floor plans, photos, certificates, supporting docs) | No lifecycle policy found | `bops-terraform/modules/ecs_bops/s3.tf` |
| **S3 Import** | Bulk import data files | Versioned, prevent_destroy | `bops-terraform/modules/ecs_bops/s3.tf` |
| **S3 Assets** | Static CSS, JS, images | No lifecycle policy | `bops-terraform/modules/ecs_bops/assets.tf` |
| **CloudWatch Logs** | Application logs (web, worker, console) | 30 days | `bops-terraform/modules/ecs_bops/ecs.tf` |

### B3) Queues and Messaging

| Queue/Topic | Type | Producers | Consumers | Defined In |
|---|---|---|---|---|
| **low_priority** (Sidekiq) | Redis queue | Web app (default queue) | Worker (Sidekiq) | `config/sidekiq.yml` |
| **high_priority** (Sidekiq) | Redis queue | Web app (urgent jobs) | Worker (Sidekiq) | `config/sidekiq.yml` |
| **submissions** (Sidekiq) | Redis queue | API submission handlers | Worker (Sidekiq) | `config/sidekiq.yml` |
| **Deployment notifications** (SNS) | Notification topic | CodeDeploy events | AWS Chatbot → Slack | `bops-terraform/modules/ecs_bops/codedeploy.tf` |
| **RDS events** (SNS) | Notification topic | CloudWatch EventBridge | AWS Chatbot → Slack | `bops-terraform/monitoring/database.tf` |
| **AWS Health** (SNS) | Notification topic | CloudWatch EventBridge | AWS Chatbot → Slack | `bops-terraform/monitoring/health.tf` |

### B3.1) Scheduled Jobs

| Job | Schedule | Queue | Purpose | Defined In |
|---|---|---|---|---|
| CloseRedLineBoundaryChangeValidationRequestJob | 9am daily | low_priority | Auto-close expired boundary change requests | `config/sidekiq.yml` |
| CloseDescriptionChangeJob | 9am daily | low_priority | Auto-close expired description change requests | `config/sidekiq.yml` |
| ClosePreCommencementConditionValidationRequestJob | 9am daily | low_priority | Auto-close expired pre-commencement conditions | `config/sidekiq.yml` |
| EnqueueUpdateConsulteeEmailStatusJob | Hourly at :09 | low_priority | Check GOV.UK Notify email delivery statuses | `config/sidekiq.yml` |

---

## C) Key Findings

### C1) Architectural Observations

| # | Observation | Severity | Evidence |
|---|---|---|---|
| 1 | **Single-AZ RDS by default** | MEDIUM | `modules/database/main.tf` — `multi_az = false` default. Verify if production overrides this. |
| 2 | **No S3 lifecycle policies on uploads** | LOW | `modules/ecs_bops/s3.tf` — no lifecycle rules on uploads bucket. Unbounded storage growth. |
| 3 | **No application-level caching** | LOW | `config/environments/production.rb` — cache_store commented out, despite having ElastiCache available. |
| 4 | **No auto-scaling policies** | LOW | No ECS auto-scaling found in Terraform. Fixed task counts (2 web + 2 worker + 1 console). Verify if this is intentional. |

### C2) Unknowns to Confirm

| # | Unknown | Impact | Where to Verify |
|---|---|---|---|
| 1 | **Is RDS multi-AZ enabled in production?** | HIGH — data availability | Check AWS console or Terraform state |
| 2 | **What RDS instance class runs in production?** | MEDIUM — performance | Default is `db.t3.small` in module; check if production overrides it |
| 3 | **Are there any Lambda@Edge functions on CloudFront?** | MEDIUM — architecture | Only a CloudFront Function (`remove-blobs-prefix`) found in Terraform |
| 4 | **Is there a backup/DR strategy beyond 7-day RDS snapshots?** | MEDIUM — resilience | No cross-region replication or separate backup strategy found |
| 5 | **Are there additional environments beyond staging/production/pentest/sandbox?** | LOW — architecture | Only 4 environments found in Terraform |

### C3) Next Steps

1. **Verify production overrides**: Check Terraform state to confirm RDS instance class, multi-AZ, and other module defaults
2. **Inspect AV scanning setup**: `monitoring/bucket_av.tf` exists — verify it covers the uploads bucket
3. **Review additional CloudFront distributions**: May exist for the applicants subdomain
4. **Check for auto-scaling policies**: Verify if fixed task counts are intentional or if scaling is needed
5. **Confirm tenant list**: Verify the list of production local authorities matches Terraform configuration
