#!/bin/bash
# ============================================================
# Terraform output → Ansible inventory(hosts.ini) 자동 생성
# 사용법: bash scripts/gen_inventory.sh
# 전제: terraform apply 완료 상태
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform"
INVENTORY_FILE="$SCRIPT_DIR/../ansible/inventory/hosts.ini"

# WSL2에서 Windows terraform.exe 자동 감지
if command -v terraform &>/dev/null; then
  TF="terraform"
elif command -v terraform.exe &>/dev/null; then
  TF="terraform.exe"
else
  # Windows 일반 설치 경로 탐색
  for candidate in \
    "/mnt/c/Program Files/Terraform/terraform.exe" \
    "/mnt/c/HashiCorp/Terraform/terraform.exe" \
    "/mnt/c/Users/$USER/AppData/Local/Programs/Terraform/terraform.exe"; do
    if [ -f "$candidate" ]; then
      TF="$candidate"
      break
    fi
  done
fi

if [ -z "$TF" ]; then
  echo "ERROR: terraform을 찾을 수 없습니다."
  echo "  Windows: https://developer.hashicorp.com/terraform/install"
  echo "  WSL2:    sudo snap install terraform --classic"
  exit 1
fi

echo "terraform 경로: $TF"
echo "Terraform output 조회 중..."
cd "$TF_DIR"

MASTER_IP=$("$TF" output -raw master_public_ip)
WORKER_IPS=$("$TF" output -json worker_public_ips | python3 -c "import sys,json; [print(ip) for ip in json.load(sys.stdin)]")

echo "Master IP : $MASTER_IP"
echo "Worker IPs: $(echo "$WORKER_IPS" | tr '\n' ' ')"

cat > "$INVENTORY_FILE" << EOF
# 자동 생성됨 — scripts/gen_inventory.sh
# $(date)

[master]
k8s-master ansible_host=${MASTER_IP}

[workers]
EOF

i=0
while IFS= read -r ip; do
  echo "k8s-worker-${i} ansible_host=${ip}" >> "$INVENTORY_FILE"
  i=$((i + 1))
done <<< "$WORKER_IPS"

cat >> "$INVENTORY_FILE" << EOF

[k8s_cluster:children]
master
workers

[k8s_cluster:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
EOF

echo ""
echo "hosts.ini 생성 완료: $INVENTORY_FILE"
cat "$INVENTORY_FILE"
