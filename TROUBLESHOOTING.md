# 🐛 Troubleshooting Log

A running record of every real issue hit while building this project, and how it was fixed. Kept as a quick reference — symptom → cause → fix — rather than a full narrative, since the goal here is fast lookup, not storytelling.

---

## Docker & local environment

**`permission denied while trying to connect to the docker API`**
Cause: user added to the `docker` group but the session never refreshed.
Fix: `sudo usermod -aG docker $USER`, then fully log out and back in (not just `newgrp`).

**ECR push works with `docker login` but fails with `sudo docker push`**
Cause: `sudo` uses a separate credential store than your regular user session.
Fix: authenticate and push consistently without `sudo` once the user is in the `docker` group.

---

## AWS / Terraform

**`No subnets found for the default VPC`**
Cause: the default VPC existed but had no subnets — not guaranteed by AWS despite the name "default."
Fix: create a subnet explicitly (`aws ec2 create-default-subnet` or a Terraform `aws_subnet` resource).

**Blackhole route to internet gateway** (`EC2 Instance Connect... blackhole route`)
Cause: repeated `terraform destroy`/`apply` cycles recreated the Internet Gateway each time, but a *pre-existing* route table kept referencing the old (now-deleted) IGW ID.
Fix: stop referencing an existing route table — have Terraform create and own its **own** `aws_route_table` with the route embedded, so destroy/apply always recreates a consistent pair.

**`VcpuLimitExceeded`**
Cause: AWS free-tier accounts default to a 1 vCPU limit, capping concurrent `t2.micro` instances.
Fix: consolidate services onto fewer instances (we merged 4 planned instances into 2: web tier + data tier).

**EC2 can't pull from ECR (`pull access denied`, `no basic auth credentials`)**
Cause: Docker has no implicit AWS credentials — EC2 instances need an **IAM instance profile** explicitly attached.
Fix: create an IAM role + instance profile with `AmazonEC2ContainerRegistryReadOnly`, attach it via `aws_iam_instance_profile` in Terraform (or `aws ec2 associate-iam-instance-profile` after the fact).

**AWS Budgets email says it can't publish to SNS**
Cause: the SNS topic had no policy allowing the `budgets.amazonaws.com` service principal to publish.
Fix: attach an `aws_sns_topic_policy` explicitly granting `SNS:Publish` to that principal.

---

## Networking across hosts (EC2 / general)

**`redis.exceptions.ConnectionError: ... Temporary failure in name resolution`**
Cause: container-name DNS (`host='redis'`) only resolves within a single Docker Compose network — it doesn't work once services are split across separate EC2 hosts.
Fix: pass real private IPs via environment variables, and make sure the app code actually reads them (`os.environ.get('REDIS_HOST', 'redis')`) instead of a hardcoded hostname.

**Redis/PostgreSQL unreachable from another host despite correct IP**
Cause: containers were started without `-p` exposing the port to the host network — only reachable inside their own Docker bridge network.
Fix: re-run with `-p 6379:6379` / `-p 5432:5432` so the port is bound to the host interface, not just the container network.

---

## CI/CD (Jenkins → GitHub Actions)

**Gitea webhook: `webhook can only call allowed HTTP servers`**
Cause: Gitea blocks outbound webhook calls to internal hostnames by default.
Fix: add `ALLOWED_HOST_LIST = jenkins` under `[webhook]` in Gitea's `app.ini`.

**Jenkins webhook returns Jenkins login page instead of triggering a build**
Cause: webhook URL had no credentials, so Jenkins redirected to `/login`.
Fix: embed credentials in the webhook URL, or (better) install the Gitea plugin and use its dedicated trigger instead of the generic remote-build token URL.

**GitHub push rejected: `refusing to allow a Personal Access Token to create or update workflow`**
Cause: token lacked the `workflow` scope, required specifically to push `.github/workflows/*.yml`.
Fix: regenerate the token with `workflow` scope included.

**Fine-grained GitHub token gets `403` on push despite looking "read/write"**
Cause: fine-grained tokens can list broad read permissions while still lacking actual write access unless every relevant scope is explicitly checked.
Fix: use a **classic** token with the top-level `repo` scope for simplicity.

**`git push` rejected: large file exceeds GitHub's 100MB limit**
Cause: Terraform provider binaries (`.terraform/providers/.../terraform-provider-aws_*`, several hundred MB) got committed.
Fix: add `.terraform/`, `*.tfstate*` to `.gitignore`, then purge them from history with `git filter-branch` (a simple `git rm --cached` isn't enough once they're already in prior commits).

**Decided to drop Jenkins entirely** in favor of GitHub Actions + a self-hosted runner — fewer moving parts (no Gitea, no webhook plumbing, no Jenkins credential store) for the same end result.

---

## Git repo structure

**`fatal: Pathspec '...' is in submodule 'infra'`**
Cause: a leftover `.git` directory inside the `infra/` folder (from an earlier separate `git init`) made the parent repo treat it as a submodule, even with no `.gitmodules` file present.
Fix: `rm -rf infra/.git`, then `git rm --cached infra && git add infra/` to re-track it as normal files.

**`.gitignore` entries silently stopped working after a folder rename**
Cause: `.gitignore` still referenced the old folder name (`voting-app-infra/`) after it was renamed to `infra/`.
Fix: update the ignore paths to match the current folder name.

---

## Kubernetes cluster bootstrap (`kubeadm`)

**`[ERROR FileExisting-conntrack]: conntrack not found in system path`**
Fix: `sudo dnf install -y conntrack-tools` (Fedora) or `sudo apt-get install -y conntrack` (Ubuntu) before `kubeadm init`/`join`.

**Worker node stuck: `kubelet is not healthy`, logs show `bootstrap-kubelet.conf: no such file or directory`**
Cause (the real one, after a lot of dead ends): Fedora's **native** `kubernetes1.36` package silently took priority over the pinned `pkgs.k8s.io/core:/stable:/v1.31` repo, so the worker's kubelet was 5 minor versions ahead of the control plane (`v1.36.2` vs `v1.31.14`) — a gap far beyond Kubernetes' supported version skew.
Fix: `rpm -qf /usr/bin/kubelet` to identify the real owning package, remove it, and install the pinned version explicitly by exact version string from the correct repo. Match versions on every node.

**Same cluster, migrated to Ubuntu workers instead of debugging Fedora further**
Rather than keep fighting Fedora's native Kubernetes packaging conflicting with the pinned upstream repo, the two worker VMs were rebuilt on Ubuntu Server, where the apt-based `pkgs.k8s.io` repo installs cleanly with no competing native package.

**CoreDNS pods stuck in `ContainerCreating` for hours**
Cause: `FailedCreatePodSandBox ... failed to find plugin "loopback" in path [/opt/cni/bin]` — Flannel's own binary was installed, but the standard CNI plugin suite it depends on (`loopback`, `bridge`, `host-local`, etc.) was never installed alongside it.
Fix: download and extract the [containernetworking/plugins](https://github.com/containernetworking/plugins) release archive into `/opt/cni/bin` on every node, then delete the CoreDNS pods so they retry.

---

## Kubernetes manifests

**`kubectl apply` reports `unchanged` for every resource — but doesn't even mention one Deployment**
Cause: a scripted find-and-replace accidentally duplicated a YAML block and swallowed the `---` document separator before the next resource, silently merging two documents into one invalid one. `kubectl apply` skips a malformed document without erroring loudly.
Fix: always check that the apply output lists **every** expected resource name, not just that the command exited without error. Validate multi-document YAML with `yaml.safe_load_all()` before applying.

**PostgreSQL data disappears every time the pod restarts, despite a PersistentVolume being `Bound`**
Cause: the above YAML merge bug meant `volumeMounts`/`volumes` were never actually present in the live Deployment, even though the PV and PVC themselves were correctly bound.
Fix: same as above — verify the applied Deployment spec directly (`kubectl get deployment ... -o yaml`) rather than assuming a `Bound` PVC means the mount is actually wired up.

**Worker pod running and healthy, but `kubectl logs` shows absolutely nothing**
Cause: Python buffers `stdout` by default when it isn't attached to a real terminal — normal for any containerized process — so `print()` statements can sit unflushed indefinitely.
Fix: add `ENV PYTHONUNBUFFERED=1` to the Dockerfile.

**Prometheus pod stuck `Pending` despite a `nodeSelector` targeting the master node**
Cause: the control-plane node has a `node-role.kubernetes.io/control-plane:NoSchedule` **taint** by default, and a `nodeSelector` alone doesn't override a taint — a matching **toleration** is required too.
Fix: add a `tolerations` entry matching the taint's key and effect.

**Prometheus scrape target `kubernetes-nodes` failing: `x509: cannot validate certificate ... doesn't contain any IP SANs`**
Cause: kubelet's self-signed serving certificate only covers its hostname, not the IP address Prometheus's service discovery uses to reach it.
Fix: set `insecure_skip_verify: true` in that scrape job's `tls_config` (acceptable on a trusted private network; not a substitute for real cert SANs in production).

**Same target then fails with `403 Forbidden ... resource=nodes, subresource=metrics`, despite `kubectl auth can-i get nodes/metrics` returning `yes`**
Cause: the ClusterRole listed `nodes` and `nodes/proxy` but not the specific `nodes/metrics` subresource string, which kubelet's authorizer checks independently — `kubectl auth can-i` on the general `nodes` resource doesn't fully reflect this stricter runtime check.
Fix: add `nodes/metrics` explicitly to the ClusterRole's `resources` list.

---

## Security items flagged for later hardening

These were intentionally simplified to keep the lab moving, and are called out here rather than fixed silently:

- PostgreSQL Secret values (`kubectl create secret ... --from-literal=...`) are fine at rest inside `etcd`, but were briefly present in plaintext in an early YAML draft before being moved to an imperative `kubectl create secret` command — never actually committed to Git, but worth knowing base64 in a Secret object is encoding, not encryption.
- `hostPath` PersistentVolume directory on worker1 was set to `chmod 777` to sidestep a container-user permission mismatch — fine for a lab, not for production.
- SELinux was temporarily set to `Permissive` on worker1 while diagnosing the kubelet crash loop, and should be reverted to `Enforcing` once the root cause (version mismatch) was confirmed as the real fix.
