# OCI k3s 클러스터 (1 Master + 3 Worker)

## 사전 준비

### 1. OCI API Key 생성
```
OCI 콘솔 → 우측 상단 프로필 → My Profile → API Keys → Add API Key
→ Generate API Key Pair → Download Private Key → Add
→ 표시되는 Configuration File 내용을 복사해둠
```

### 2. ~/.oci/config 파일 생성
```ini
[DEFAULT]
user=ocid1.user.oc1..xxxxxxxxx
fingerprint=xx:xx:xx:xx:...
tenancy=ocid1.tenancy.oc1..xxxxxxxxx
region=ap-chuncheon-1
key_file=~/.oci/oci_api_key.pem
```

### 3. OCI 콘솔에서 미리 확인할 OCID
- Compartment OCID: Identity → Compartments
- Subnet OCID: Networking → Virtual Cloud Networks → Default VCN → Subnets → **Public Subnet**
- Security List OCID: Networking → VCN → Security Lists → Default Security List
- Image OCID: 01_provision.yml이 자동 조회하므로 불필요

### 4. SSH 키 생성 (없는 경우)
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

### 5. ~/.oci 설정
```bash
mkdir -p ~/.oci
cp .oci/config ~/.oci/config
cp .oci/*.pem ~/.oci/
chmod 600 ~/.oci/*
```

### 6. Ansible 및 OCI 컬렉션 설치
```bash
pipx install ansible-core
pipx inject ansible-core oci
ansible-galaxy collection install -r requirements.yml
```

### 7. group_vars/all.yml에 OCID 입력
```bash
# 평문으로 사용하거나 vault로 암호화
ansible-vault encrypt group_vars/all.yml
```

## 실행 순서

```bash
# 1. OCI Security List 포트 오픈
ansible-playbook playbooks/03_security.yml --ask-vault-pass

# 2. 인스턴스 4대 생성 (약 5분) - Out of host capacity 시 재시도
ansible-playbook playbooks/01_provision.yml --ask-vault-pass

# 3. k3s 설치 (약 10분)
ansible-playbook playbooks/02_install_k3s.yml --ask-vault-pass

# 4. 로컬에서 kubectl 사용
export KUBECONFIG=./kubeconfig
kubectl get nodes
```

## GPU 워커로 교체 시

group_vars/all.yml에서 특정 워커의 shape 변경:
```yaml
# VM.GPU.A10.1 = NVIDIA A10 (x86)
# VM.GPU3.1    = NVIDIA V100 (x86)
```
주의: GPU shape은 x86이므로 image_ocid도 amd64 버전으로 변경 필요

## 삭제 (크레딧 절약)

```bash
ansible-playbook playbooks/99_destroy.yml --ask-vault-pass
```
# k3s-test
