# ============================================================
# Security List 규칙 관리
# 기존 Default Security List를 Terraform으로 관리
#
# 최초 1회: terraform import oci_core_default_security_list.k8s <security_list_ocid>
# ============================================================
resource "oci_core_default_security_list" "k8s" {
  manage_default_resource_id = var.security_list_ocid

  # SSH
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # k3s API Server
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # HTTP
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # NodePort 범위
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  # 클러스터 내부 통신 전체 허용
  ingress_security_rules {
    protocol = "all"
    source   = "10.0.0.0/16"
  }

  # Egress 전체 허용
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}
