#!/bin/bash
# 인스턴스 최초 부팅 시 실행되는 cloud-init 스크립트
# Ansible이 SSH 접속하기 전에 기본 환경을 준비합니다

# iptables 초기화 (OCI Ubuntu 기본 설정 해제)
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# python3 설치 (Ansible 실행에 필요)
apt-get update -qq
apt-get install -y -qq python3 python3-pip

# 완료 마커
touch /var/lib/cloud-init-done
