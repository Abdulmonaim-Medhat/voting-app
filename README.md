# Voting App — End-to-End DevOps Pipeline

A hands-on DevOps lab project built from scratch: a microservices voting app (Al-Ahly vs El-Zamalek derby edition) deployed through a full modern toolchain — containerization, infrastructure as code, configuration management, and CI/CD.

This project was built incrementally to practice and demonstrate real DevOps/SRE skills, moving from local Docker containers to cloud infrastructure on AWS.

## Architecture

```
Browser
   │
   ▼
[Vote app - Flask]  ──push──▶  [Redis queue]
                                     │
                                     ▼
                              [Worker - Python]
                                     │
                                     ▼
                            [PostgreSQL]  ◀──read──  [Result app - Flask + SSE]
```

**Services**
- `vote/` — Flask app where users cast votes (Al-Ahly vs El-Zamalek), pushes to Redis
- `worker/` — Python worker that consumes votes from Redis and writes to PostgreSQL
- `result/` — Flask app that reads from PostgreSQL and streams live results via Server-Sent Events (no page reloads)
- `redis` — message queue between vote app and worker
- `postgres` — persistent vote storage

## Tech stack

| Layer | Tool |
|---|---|
| Application | Python (Flask), Redis, PostgreSQL |
| Containerization | Docker, Docker Compose |
| Version control | Git, GitHub |
| CI/CD | GitHub Actions (self-hosted runner) |
| Infrastructure as Code | Terraform (AWS VPC, EC2, IAM, budgets) |
| Configuration management | Ansible |
| Container registry | Amazon ECR |
| Cloud | AWS (EC2 free tier, IAM, CloudWatch/Budgets) |

## Project evolution

This project was built in stages, each one adding a layer of the real-world DevOps toolchain:

1. **Containerize the app** — Flask + Redis + PostgreSQL + worker, each in its own Dockerfile
2. **Docker Compose** — single-command local orchestration with health checks and dependency ordering
3. **Version control** — Git repository, pushed to GitHub
4. **CI/CD** — iterated through two approaches:
   - Self-hosted Gitea + Jenkins (webhook-triggered pipeline)
   - Simplified to **GitHub Actions with a self-hosted runner** — push to `main` automatically builds images and redeploys containers
5. **Infrastructure as Code** — Terraform provisions a 2-tier AWS architecture:
   - Web tier EC2 (vote + result apps)
   - Data tier EC2 (Redis + PostgreSQL + worker)
   - VPC, subnet, internet gateway, route table, security groups, IAM instance profile for ECR pull access — all Terraform-managed to avoid configuration drift (including a fix for a recurring "blackhole route" bug caused by managing an existing default route table instead of owning it end-to-end)
6. **Configuration management** — Ansible playbooks install Docker, authenticate to ECR, and deploy each service to the right tier
7. **Cost control** — AWS Budgets + SNS alerts at 80%/100% actual and forecasted spend, kept the whole project within free tier

## Running it locally

```bash
docker compose up -d
```

- Vote: `http://localhost:5000`
- Results: `http://localhost:3000`

## Running it on AWS

```bash
cd infra
terraform init
terraform apply

# build + push images to ECR, then:
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

## What's next

- **Kubernetes** — migrate from EC2 + Ansible to a Kubernetes deployment, starting with Minikube locally and then Amazon EKS
- **Monitoring** — Prometheus + Grafana for metrics, dashboards, and alerting
- **GitOps** — potentially move to a Kubernetes-native deployment flow

## Lessons learned

A few real debugging sessions worth mentioning, since they're as valuable as the working result:
- Docker Compose services communicating by container name only work within the same Compose network — across separate EC2 hosts, services must connect via private IP, and env vars need to actually be read by the app code (not hardcoded)
- Default AWS VPCs don't always come with subnets or an internet gateway already wired up — Terraform should own the full networking stack rather than referencing pre-existing resources, to avoid orphaned/blackholed routes after repeated destroy/apply cycles
- EC2 instances need an IAM instance profile to pull from ECR — the Docker CLI has no implicit AWS credentials
- Free tier accounts default to a 1 vCPU limit, which caps concurrent `t2.micro` instances

---

*Built by Kareem — network/infrastructure engineer transitioning into DevOps/SRE.*
