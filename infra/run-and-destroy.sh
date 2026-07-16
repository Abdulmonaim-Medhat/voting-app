#!/bin/bash
set -e

ECR="034362069931.dkr.ecr.us-east-1.amazonaws.com"
cd ~/Documents/projects/voting-app

echo "=== Authenticating to ECR ==="
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR

echo "=== Creating ECR repos ==="
aws ecr create-repository --repository-name voting-app/vote --region us-east-1 2>/dev/null || true
aws ecr create-repository --repository-name voting-app/worker --region us-east-1 2>/dev/null || true
aws ecr create-repository --repository-name voting-app/result --region us-east-1 2>/dev/null || true

echo "=== Building images ==="
docker build -t vote-app ./vote
docker build -t vote-worker ./worker
docker build -t vote-result ./result

echo "=== Tagging images ==="
docker tag vote-app:latest $ECR/voting-app/vote:latest
docker tag vote-worker:latest $ECR/voting-app/worker:latest
docker tag vote-result:latest $ECR/voting-app/result:latest

echo "=== Pushing images ==="
docker push $ECR/voting-app/vote:latest
docker push $ECR/voting-app/worker:latest
docker push $ECR/voting-app/result:latest

echo "=== Provisioning infra ==="
cd infra
terraform apply -auto-approve

echo "=== Getting IPs ==="
WEB_IP=$(terraform output -raw web_public_ip)
DATA_IP=$(terraform output -raw data_public_ip)
DATA_PRIVATE=$(terraform output -raw data_private_ip)

echo "Web:  $WEB_IP"
echo "Data: $DATA_IP"

echo "=== Updating Ansible inventory ==="
cat > ansible/inventory.ini << INVENTORY
[web]
$WEB_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/voting-app-key

[data]
$DATA_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/voting-app-key

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
INVENTORY

echo "=== Updating data private IP in playbook ==="
sed -i "s/data_private_ip: .*/data_private_ip: \"$DATA_PRIVATE\"/" ansible/playbook.yml

echo "=== Waiting for instances to boot ==="
sleep 30

echo "=== Running Ansible ==="
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml

echo ""
echo "========================================="
echo "App is live — you have 20 minutes"
echo "Vote:   http://$WEB_IP:5000"
echo "Result: http://$WEB_IP:3000"
echo "========================================="
echo ""

echo "=== Countdown: 20 minutes ==="
for i in {20..1}; do
  echo "$i minutes remaining..."
  sleep 60
done

echo "=== Destroying infra ==="
terraform destroy -auto-approve

echo "=== Cleaning up ECR ==="
aws ecr delete-repository --repository-name voting-app/vote --force
aws ecr delete-repository --repository-name voting-app/worker --force
aws ecr delete-repository --repository-name voting-app/result --force

echo "=== All done — infra destroyed and ECR cleaned ==="
