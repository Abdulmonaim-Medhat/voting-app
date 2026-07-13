<div align="center">

# 🗳️ Voting App — End-to-End DevOps Pipeline

### Al-Ahly 🔴 vs El-Zamalek ⚪ — a full DevOps lab built from scratch

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-DC382D?style=for-the-badge&logo=redis&logoColor=white)](https://redis.io/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)](https://flask.palletsprojects.com/)

![Status](https://img.shields.io/badge/status-active-brightgreen?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)
![Made with](https://img.shields.io/badge/made%20with-%E2%9D%A4%EF%B8%8F%20%2B%20%E2%98%95-orange?style=flat-square)

*A hands-on DevOps lab: containers → CI/CD → infrastructure as code → cloud deployment*

</div>

---

## 📋 Table of Contents

- [🏗️ Architecture](#️-architecture)
- [🧰 Tech Stack](#-tech-stack)
- [🚀 Project Evolution](#-project-evolution)
- [▶️ Running Locally](#️-running-locally)
- [☁️ Running on AWS](#️-running-on-aws)
- [🗺️ Roadmap](#️-roadmap)
- [🐛 Lessons Learned](#-lessons-learned)

---

## 🏗️ Architecture

```
                     🌐 Browser
                        │
                        ▼
        ┌───────────────────────────┐
        │   🗳️  Vote App (Flask)     │
        │      port :5000            │
        └───────────┬────────────────┘
                     │ push vote
                     ▼
        ┌───────────────────────────┐
        │   📥  Redis (queue)        │
        └───────────┬────────────────┘
                     │ consume
                     ▼
        ┌───────────────────────────┐
        │   ⚙️  Worker (Python)      │
        └───────────┬────────────────┘
                     │ write
                     ▼
        ┌───────────────────────────┐
        │   🐘  PostgreSQL            │
        └───────────┬────────────────┘
                     │ read
                     ▼
        ┌───────────────────────────┐
        │  📊  Result App (SSE)      │
        │      port :3000            │
        └───────────────────────────┘
```

| Service | Role | Tech |
|---|---|---|
| 🗳️ `vote/` | Users cast votes (Al-Ahly vs El-Zamalek) | Flask |
| ⚙️ `worker/` | Consumes votes from Redis, writes to PostgreSQL | Python |
| 📊 `result/` | Live results via Server-Sent Events — no page reloads | Flask + SSE |
| 📥 `redis` | Message queue between vote app and worker | Redis |
| 🐘 `postgres` | Persistent vote storage | PostgreSQL |

---

## 🧰 Tech Stack

<div align="center">

| Layer | Tools |
|:---|:---|
| 🎯 **Application** | Python · Flask · Redis · PostgreSQL |
| 📦 **Containerization** | Docker · Docker Compose |
| 🔀 **Version Control** | Git · GitHub |
| 🔁 **CI/CD** | GitHub Actions (self-hosted runner) |
| 🏗️ **Infrastructure as Code** | Terraform (AWS VPC, EC2, IAM, budgets) |
| ⚙️ **Config Management** | Ansible |
| 📮 **Container Registry** | Amazon ECR |
| ☁️ **Cloud** | AWS (EC2 free tier, IAM, CloudWatch, Budgets) |

</div>

---

## 🚀 Project Evolution

This project was built in stages — each one layering in a real piece of the modern DevOps toolchain:

1. **📦 Containerize the app**
   Flask + Redis + PostgreSQL + worker, each in its own Dockerfile

2. **🧩 Docker Compose**
   Single-command local orchestration with health checks and dependency ordering

3. **🔀 Version control**
   Git repo pushed to GitHub

4. **🔁 CI/CD** — iterated through two approaches:
   - ~~Self-hosted Gitea + Jenkins~~ (webhook-triggered pipeline)
   - ✅ **GitHub Actions with a self-hosted runner** — push to `main` auto-builds images and redeploys containers

5. **🏗️ Infrastructure as Code**
   Terraform provisions a 2-tier AWS architecture:
   - 🌐 Web tier EC2 → vote + result apps
   - 🗄️ Data tier EC2 → Redis + PostgreSQL + worker
   - Full networking stack (VPC, subnet, IGW, route table, security groups) and an IAM instance profile for ECR pulls — all Terraform-owned to eliminate drift *(including a fix for a recurring "blackhole route" bug — see [Lessons Learned](#-lessons-learned))*

6. **⚙️ Configuration management**
   Ansible playbooks install Docker, authenticate to ECR, and deploy each service to the correct tier

7. **💰 Cost control**
   AWS Budgets + SNS alerts at 80%/100% actual and forecasted spend — the entire project stays inside free tier

---

## ▶️ Running Locally

```bash
docker compose up -d
```

| Service | URL |
|---|---|
| 🗳️ Vote | http://localhost:5000 |
| 📊 Results | http://localhost:3000 |

---

## ☁️ Running on AWS

```bash
cd infra
terraform init
terraform apply

# build + push images to ECR, then:
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

---

## 🗺️ Roadmap

- [ ] ☸️ **Kubernetes** — migrate from EC2 + Ansible → Minikube locally, then Amazon EKS
- [ ] 📈 **Monitoring** — Prometheus + Grafana for metrics, dashboards, and alerting
- [ ] 🔄 **GitOps** — explore a Kubernetes-native deployment flow

---

<<<<<<< HEAD
*Built by Kareem — DevOps/SRE.*
=======
## 🐛 Lessons Learned

> Real debugging sessions worth documenting — they taught more than the tutorial parts ever could.

- 🕸️ **Container-name DNS only works within one Docker network.** Across separate EC2 hosts, services need real private IPs — and the app code has to actually *read* the env var instead of hardcoding the hostname.
- 🕳️ **The "blackhole route" bug.** Default AWS VPCs don't always ship with subnets or an internet gateway. Letting Terraform *reference* an existing route table (instead of owning the full networking stack) caused routes to silently point at deleted gateways after repeated destroy/apply cycles. Fix: Terraform creates and owns its *own* route table end-to-end.
- 🔑 **No implicit AWS credentials in Docker.** EC2 instances need an IAM instance profile to pull from ECR — the Docker CLI won't magically find credentials otherwise.
- 🧮 **Free tier vCPU limits are real.** Free tier accounts default to a 1 vCPU limit, capping how many `t2.micro` instances can run concurrently.

---

<div align="center">
 
Built by Kareem —  into DevOps/SRE 🚀


</div>
>>>>>>> 8352c55 (make README more visual with badges and better formatting)
