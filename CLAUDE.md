# OCI k3s 클러스터 프로젝트

OCI(Oracle Cloud Infrastructure) 위에 Ansible로 k3s 쿠버네티스 클러스터(1 Master + 3 Worker)를 자동 프로비저닝하는 프로젝트.

## 프로젝트 구조

```
.
├── ansible.cfg                  # Ansible 기본 설정 (remote_user: ubuntu, SSH 키: ~/.ssh/id_rsa)
├── requirements.yml             # Ansible 컬렉션 의존성
├── group_vars/
│   └── all.yml                  # OCI 자격증명 + 인스턴스 스펙 + k3s 설정 (민감정보 포함)
├── inventory/
│   ├── hosts.ini                # 실제 인벤토리 (01_provision.yml 실행 후 자동 생성됨)
│   └── hosts.ini.j2             # 인벤토리 Jinja2 템플릿
├── playbooks/
│   ├── 01_provision.yml         # OCI 인스턴스 4대 생성 + hosts.ini 자동 생성
│   ├── 02_install_k3s.yml       # k3s 설치 (master → worker 순서)
│   ├── 03_security.yml          # OCI Security List 포트 오픈
│   └── 99_destroy.yml           # 전체 인스턴스 삭제
├── roles/
│   ├── common/tasks/main.yml    # 공통 초기화 (swap off, kernel module 등)
│   ├── master/tasks/main.yml    # k3s server 설치
│   └── worker/tasks/main.yml    # k3s agent 설치
├── scripts/
│   └── cloud-init.sh            # 인스턴스 부팅 시 실행되는 초기화 스크립트
└── .oci/
    └── config                   # OCI CLI/SDK 인증 설정
```

## 인프라 스펙

| 구분 | Shape | OCPU | Memory |
|------|-------|------|--------|
| Master x1 | VM.Standard.A1.Flex (ARM) | 2 | 12GB |
| Worker x3 | VM.Standard.A1.Flex (ARM) | 1 | 6GB |

- OS: Ubuntu 24.04 aarch64 (이미지 OCID는 01_provision.yml에서 자동 조회)
- Region: ap-osaka-1
- k3s 버전: v1.29.3+k3s1

## 실행 순서

```bash
# 1. 의존성 설치 (pipx 사용 - 시스템 Python 격리)
pipx install ansible-core
pipx inject ansible-core oci
ansible-galaxy collection install -r requirements.yml

# 2. OCI Security List 포트 오픈
ansible-playbook playbooks/03_security.yml --ask-vault-pass

# 3. 인스턴스 4대 생성 (약 5분) → hosts.ini 자동 생성됨
ansible-playbook playbooks/01_provision.yml --ask-vault-pass

# 4. k3s 설치 (약 10분)
ansible-playbook playbooks/02_install_k3s.yml --ask-vault-pass

# 5. kubectl 확인
export KUBECONFIG=./kubeconfig
kubectl get nodes

# 삭제 (크레딧 절약)
ansible-playbook playbooks/99_destroy.yml
```

## 주요 설정 파일

### group_vars/all.yml
OCI 자격증명과 리소스 OCID가 평문으로 저장됨. 암호화 권장:
```bash
ansible-vault encrypt group_vars/all.yml
ansible-playbook playbooks/01_provision.yml --ask-vault-pass
```

### .oci/config
OCI SDK 인증 파일. API Key 방식 사용. WSL에서 실행 시 홈 디렉토리에 복사 필요:
```bash
mkdir -p ~/.oci
cp .oci/config ~/.oci/config
cp .oci/*.pem ~/.oci/
chmod 600 ~/.oci/*
```
key_file 경로가 실제 .pem 파일 위치와 일치해야 함 (`/home/username/.oci/...` 형식).

### SSH 키 생성
인스턴스 SSH 접속용 키페어. 없으면 생성:
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

## 주의사항

- **GPU shape 사용 시**: VM.GPU.A10.1 / VM.GPU3.1 은 x86 아키텍처 → image_ocid도 amd64 버전으로 변경 필요
- **hosts.ini**: 01_provision.yml 실행 전에는 placeholder(`MASTER_PUBLIC_IP` 등)가 들어있음, 직접 수정 불필요
- **instance_image_ocid**: 01_provision.yml에서 자동 조회하므로 group_vars/all.yml의 placeholder 값은 무시됨
- **Out of host capacity**: Ampere ARM 인스턴스 용량 부족 시 자주 발생. 잠시 후 재시도하거나 다른 리전(ap-tokyo-1 등) 시도
- **group_vars/all.yml 미로드**: `hosts: localhost` 플레이북(01, 03, 99)은 인벤토리 없이 실행되어 group_vars를 자동으로 읽지 않음 → `vars_files`로 명시적 로드 처리됨
