<div align="center">

# 🗳️ Voting App — End-to-End DevOps Pipeline

### Al-Ahly 🔴 vs El-Zamalek ⚪ — a full DevOps lab built from scratch

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com/)
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
- [☸️ Running on Kubernetes](#️-running-on-kubernetes)
- [📈 Monitoring](#-monitoring)
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
| 📮 **Container Registry** | Amazon ECR · Docker Hub |
| ☁️ **Cloud** | AWS (EC2 free tier, IAM, CloudWatch, Budgets) |
| ☸️ **Orchestration** | Kubernetes — 3-node bare-metal `kubeadm` cluster |
| 📈 **Monitoring** | Prometheus · Grafana · node-exporter |

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

8. **☸️ Kubernetes**
   Migrated the app onto a real 3-node bare-metal cluster built with `kubeadm` — 1 Fedora control-plane node + 2 Ubuntu worker nodes, all on separate VMs with static IPs:
   - **Deployments** for every service (redis, postgres, worker, vote ×2 replicas, result), replacing manual `docker run`/Ansible deployment
   - **Services** — `ClusterIP` for internal-only components (redis, postgres) and `NodePort` for external access (vote, result) — Kubernetes' built-in DNS replaced the private-IP wiring that AWS/Ansible required
   - **Secrets** for DB credentials, created imperatively (`kubectl create secret`) so nothing sensitive ever touches a file on disk or Git history
   - **PersistentVolume + PersistentVolumeClaim** (`hostPath`, pinned to a worker node via `nodeAffinity`) so PostgreSQL data survives pod restarts — verified by deleting the pod mid-test and confirming votes were still there after

9. **📈 Monitoring**
   Deployed Prometheus + Grafana into their own `monitoring` namespace on the same cluster:
   - **RBAC** (ServiceAccount + ClusterRole + ClusterRoleBinding) so Prometheus can query the Kubernetes API for service discovery — least-privilege, read-only
   - **Prometheus** scrapes the API server, kubelet on all 3 nodes, and a **node-exporter DaemonSet** (one pod per node, `hostNetwork`/`hostPID`) for real OS-level CPU/memory/disk metrics
   - **Grafana** as the visualization layer, connected to Prometheus as a data source over Kubernetes' internal DNS
   - Debugged a genuine cross-node networking failure — see [Lessons Learned](#-lessons-learned) — traced via `tcpdump` down to a Fedora firewalld zone silently dropping VXLAN-forwarded pod traffic

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

## ☸️ Running on Kubernetes

A real 3-node cluster — no Minikube abstraction — built with `kubeadm`:

| Node | OS | Role |
|---|---|---|
| master | Fedora | control-plane |
| worker1 | Ubuntu 26.04 | worker |
| worker2 | Ubuntu 26.04 | worker |

```bash
kubectl apply -f infra/k8s/postgres-storage.yaml   # PV + PVC first
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_USER=kareem \
  --from-literal=POSTGRES_PASSWORD=secret \
  --from-literal=POSTGRES_DB=vote
kubectl apply -f infra/k8s/voting-app-k8s.yaml
```

| Service | URL |
|---|---|
| 🗳️ Vote | http://\<any-node-ip\>:30000 |
| 📊 Results | http://\<any-node-ip\>:30001 |

---

## 📈 Monitoring

Prometheus + Grafana run in their own `monitoring` namespace on the same 3-node cluster:

```bash
kubectl create namespace monitoring
kubectl apply -f infra/k8s/prometheus-rbac.yaml
kubectl apply -f infra/k8s/prometheus-config.yaml
kubectl apply -f infra/k8s/prometheus-deployment.yaml
kubectl apply -f infra/k8s/node-exporter.yaml
kubectl apply -f infra/k8s/grafana-deployment.yaml
```

| Service | URL |
|---|---|
| 📊 Prometheus | http://\<any-node-ip\>:30090 |
| 📈 Grafana | http://\<any-node-ip\>:30030 |

**What's collected:**
- Kubernetes API server health
- Per-node kubelet/cAdvisor metrics (all 3 nodes)
- Real OS-level metrics via a **node-exporter DaemonSet** — one pod per node

**Next:** Thanos sidecar for long-term metric storage, starting with a local filesystem object-store backend before optionally moving to S3.

---

## 🗺️ Roadmap

- [x] ☸️ **Kubernetes** — 3-node bare-metal `kubeadm` cluster, Deployments/Services/Secrets/PersistentVolumes
- [x] 📈 **Monitoring** — Prometheus + Grafana + node-exporter DaemonSet
- [ ] 🗄️ **Thanos** — long-term metric storage, starting with local filesystem backend before S3
- [ ] 🔄 **GitOps** — explore a Kubernetes-native deployment flow
- [ ] 🔐 **Security hardening** — replace `hostPath` 777 permissions, move secrets to an external manager, re-enable SELinux enforcing on worker nodes

---

## 🐛 Lessons Learned

> Real debugging sessions worth documenting — they taught more than the tutorial parts ever could.

- 🕸️ **Container-name DNS only works within one Docker network.** Across separate EC2 hosts, services need real private IPs — and the app code has to actually *read* the env var instead of hardcoding the hostname.
- 🕳️ **The "blackhole route" bug.** Default AWS VPCs don't always ship with subnets or an internet gateway. Letting Terraform *reference* an existing route table (instead of owning the full networking stack) caused routes to silently point at deleted gateways after repeated destroy/apply cycles. Fix: Terraform creates and owns its *own* route table end-to-end.
- 🔑 **No implicit AWS credentials in Docker.** EC2 instances need an IAM instance profile to pull from ECR — the Docker CLI won't magically find credentials otherwise.
- 🧮 **Free tier vCPU limits are real.** Free tier accounts default to a 1 vCPU limit, capping how many `t2.micro` instances can run concurrently.
- 🌐 **Missing CNI plugin binaries silently break cluster DNS.** Flannel's own binary isn't enough — the standard CNI plugin suite (`loopback`, `bridge`, `host-local`, etc.) has to be installed separately in `/opt/cni/bin`, or CoreDNS pods hang forever in `ContainerCreating`.
- 🔢 **Kubernetes version skew matters — a lot.** A kubelet running 5 minor versions ahead of the control plane (caused by a Linux distro's *native* Kubernetes package silently taking priority over the pinned upstream repo) produces confusing, unrelated-looking crash loops. Always verify `kubelet --version` matches the control plane exactly on every node.
- 📝 **`kubectl apply` fails silently on malformed multi-document YAML.** A missing `---` separator between two resources merges them into one invalid document — `kubectl apply` just skips it without erroring, so always check the apply output lists every expected resource, not just that the command exited cleanly.
- 🖨️ **Python's stdout buffering hides container logs.** Without `ENV PYTHONUNBUFFERED=1` in the Dockerfile, a perfectly healthy Python process can show zero `kubectl logs` output for the container's entire lifetime.
- 🚧 **Taints repel, tolerations permit — a `nodeSelector` alone isn't enough.** The control-plane node's default `NoSchedule` taint kept blocking a `nodeSelector`-targeted Prometheus pod until a matching `toleration` was added.
- 🔥 **A cross-node VXLAN packet can arrive and still get dropped.** Grafana couldn't reach Prometheus across nodes despite correct routes and a healthy Flannel overlay — `tcpdump` on the receiving node showed the packet arriving via VXLAN and then being rejected by the node's own firewalld zone (`admin prohibited filter`), since Fedora's default `FedoraWorkstation` zone wasn't written with Kubernetes pod networking in mind. Fixed by adding the `cni0`/`flannel.1` interfaces to a `trusted` firewalld zone.

📋 **Full troubleshooting log:** every issue above, plus several smaller ones (AWS, CI/CD, Git), is documented in detail in [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).

---

<div align="center">

**Built by Kareem** — network/infrastructure engineer transitioning into DevOps/SRE 🚀

*From Huawei datacenter fabrics to Terraform state files.*

</div>
