# OCI k3s 클러스터 (1 Master + 3 Worker)

Terraform으로 OCI 인프라를 구성하고, Ansible로 k3s를 설치하는 프로젝트.

## 구조

```
.
├── terraform/
│   ├── providers.tf       # OCI provider 설정
│   ├── variables.tf       # 변수 선언
│   ├── main.tf            # 인스턴스 생성 (Master 1 + Worker 3)
│   ├── network.tf         # Security List 포트 설정
│   ├── outputs.tf         # IP 주소 출력
│   └── terraform.tfvars   # 실제 값 입력 (민감정보 → gitignore)
├── ansible/
│   ├── ansible.cfg
│   ├── group_vars/all.yml  # k3s 설정 (token, cidr 등)
│   ├── inventory/hosts.ini # gen_inventory.sh로 자동 생성
│   ├── playbooks/
│   │   └── install_k3s.yml
│   └── roles/
│       ├── common/         # swap off, iptables 초기화, 커널 설정
│       ├── master/         # k3s server 설치
│       └── worker/         # k3s agent 설치
└── scripts/
    ├── cloud-init.sh       # 인스턴스 부팅 시 초기화
    └── gen_inventory.sh    # terraform output → hosts.ini 자동 생성
```

## 인프라 스펙

| 역할 | Shape | OCPU | Memory |
|------|-------|------|--------|
| Master x1 | VM.Standard.A1.Flex (ARM) | 2 | 12GB |
| Worker x3 | VM.Standard.A1.Flex (ARM) | 1 | 6GB |

- OS: Ubuntu 24.04 aarch64 (이미지 OCID 자동 조회)
- Region: ap-osaka-1
- k3s 버전: v1.29.3+k3s1

## 사전 준비

### 1. OCI API Key 발급
```
OCI 콘솔 → 우측 상단 프로필 → My Profile → API Keys → Add API Key
→ Generate API Key Pair → Download Private Key → Add
→ 표시되는 Configuration File 내용(fingerprint 등) 복사
```

### 2. OCI 콘솔에서 미리 확인할 OCID
- Compartment OCID: Identity → Compartments
- Subnet OCID: Networking → VCN → Subnets → Public Subnet
- Security List OCID: Networking → VCN → Security Lists → Default Security List

### 3. terraform.tfvars 작성
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# 값 채우기
```

### 4. SSH 키 생성 (없는 경우)
```bash
# WSL
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Windows 경로로 복사 (Terraform이 읽어야 함)
mkdir -p /mnt/c/Users/<username>/.ssh
cp ~/.ssh/id_rsa.pub /mnt/c/Users/<username>/.ssh/
```

### 5. OCI pem 키 복사 (WSL → Windows)
```bash
mkdir -p /mnt/c/Users/<username>/.oci
cp ~/.oci/<key>.pem /mnt/c/Users/<username>/.oci/
```

### 6. Ansible 설치 (WSL)
```bash
pipx install ansible-core
```

### 7. Security List import (최초 1회)
기존 Security List를 Terraform으로 관리하려면 import 필요:
```bash
cd terraform
terraform import oci_core_default_security_list.k8s <security_list_ocid>
```

## 실행 순서

```bash
# [Windows Git Bash] 인프라 생성 (~5분)
cd terraform
terraform init
terraform apply

# [WSL] Ansible inventory 자동 생성
bash scripts/gen_inventory.sh

# [WSL] k3s 설치 (~10분)
cd ansible
ansible-playbook playbooks/install_k3s.yml
```

## kubectl 원격 접속

`ansible-playbook` 완료 후 `./kubeconfig`가 로컬에 자동 저장됩니다.

```bash
# 로컬에서 바로 사용
export KUBECONFIG=./kubeconfig
kubectl get nodes
kubectl get pods -A

# 또는 직접 scp로 가져오기
scp ubuntu@<master-ip>:~/.kube/config ~/.kube/config
```

> `scp` 방식이 일반적이나, 이 프로젝트는 Ansible이 설치 완료 시 자동으로 로컬에 복사합니다.

## 삭제 (크레딧 절약)

```bash
# [Windows Git Bash]
cd terraform
terraform destroy
```

## 주의사항

- **Out of host capacity**: Ampere ARM 인스턴스 용량 부족 시 자주 발생. 잠시 후 재시도하거나 `terraform.tfvars`에서 리전을 `ap-tokyo-1`으로 변경
- **terraform.tfvars**: 민감정보 포함. gitignore에 등록됨. 절대 커밋 금지
- **GPU shape 사용 시**: VM.GPU.A10.1 / VM.GPU3.1 은 x86 아키텍처 → `variables.tf`에서 shape 변경 시 이미지도 amd64로 바꿔야 함
