# OCI k3s 클러스터 프로젝트

Terraform으로 OCI 인프라를 프로비저닝하고, Ansible로 k3s 쿠버네티스 클러스터(1 Master + 3 Worker)를 설치하는 프로젝트.

## 프로젝트 구조

```
.
├── terraform/
│   ├── providers.tf       # OCI provider 설정
│   ├── variables.tf       # 변수 선언
│   ├── main.tf            # 인스턴스 생성 (Master 1 + Worker 3)
│   ├── network.tf         # Security List (oci_core_default_security_list)
│   ├── outputs.tf         # master_public_ip, worker_public_ips 출력
│   └── terraform.tfvars   # OCI 자격증명 + 리소스 OCID (gitignore)
├── ansible/
│   ├── ansible.cfg
│   ├── group_vars/all.yml  # k3s_version, k3s_token, pod_cidr, service_cidr
│   ├── inventory/hosts.ini # gen_inventory.sh 실행 후 자동 생성
│   ├── playbooks/
│   │   └── install_k3s.yml # common → master → worker → 상태확인 순서
│   └── roles/
│       ├── common/         # iptables 초기화, 커널 모듈, swap off, 타임존
│       ├── master/         # k3s server 설치, kubeconfig 로컬 복사
│       └── worker/         # master token 가져와서 k3s agent 조인
└── scripts/
    ├── cloud-init.sh       # 인스턴스 부팅 시 python3 설치, iptables 초기화
    └── gen_inventory.sh    # terraform output → ansible/inventory/hosts.ini 생성
```

## 인프라 스펙

| 구분 | Shape | OCPU | Memory |
|------|-------|------|--------|
| Master x1 | VM.Standard.A1.Flex (ARM) | 2 | 12GB |
| Worker x3 | VM.Standard.A1.Flex (ARM) | 1 | 6GB |

- OS: Ubuntu 24.04 aarch64 (data source로 자동 조회)
- Region: ap-osaka-1
- k3s 버전: v1.29.3+k3s1
- Pod CIDR: 10.244.0.0/16 / Service CIDR: 10.96.0.0/12

## 실행 환경 분리

| 작업 | 환경 |
|------|------|
| terraform | Windows Git Bash (Ansible은 Windows 미지원) |
| ansible-playbook | WSL2 |
| gen_inventory.sh | WSL2 (terraform.exe 자동 감지) |

## 실행 순서

```bash
# [Windows Git Bash]
cd terraform
terraform init
terraform import oci_core_default_security_list.k8s <security_list_ocid>  # 최초 1회
terraform apply

# [WSL2]
bash scripts/gen_inventory.sh
cd ansible
ansible-playbook playbooks/install_k3s.yml

# kubectl 확인
export KUBECONFIG=./kubeconfig
kubectl get nodes

# 삭제
cd terraform && terraform destroy
```

## 주요 설정

### terraform/terraform.tfvars
OCI 자격증명과 리소스 OCID 저장. gitignore에 등록됨 (커밋 금지).
pem 키 경로는 Windows 절대경로 사용: `C:/Users/<username>/.oci/<key>.pem`

### network.tf
`oci_core_default_security_list`로 기존 Default Security List를 관리.
최초 import 필요: `terraform import oci_core_default_security_list.k8s <ocid>`
오픈 포트: 22, 6443, 80, 443, 30000-32767 / 내부: 10.0.0.0/16 전체 허용

### gen_inventory.sh
WSL2에서 실행 시 terraform → terraform.exe 순으로 자동 감지.
terraform output JSON을 파싱해서 ansible/inventory/hosts.ini 생성.

### ansible/roles/master
k3s 설치 후 kubeconfig를 로컬 `./kubeconfig`로 자동 복사.
server 주소를 127.0.0.1 → Public IP로 치환해서 로컬 kubectl 접속 가능.

## 주의사항

- **Out of host capacity**: Ampere ARM 용량 부족 시 잠시 후 재시도 또는 ap-tokyo-1 시도
- **serial: 1**: 병렬 실행 시 iptables 충돌 방지를 위해 common role은 순차 실행
- **traefik/servicelb 비활성화**: 별도 ingress 컨트롤러 선택 자유도 확보
- **SSH 키**: WSL의 `~/.ssh/id_rsa.pub`을 Windows 경로(`C:/Users/.../ssh/`)로 복사 필요
