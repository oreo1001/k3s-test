# ============================================================
# OCI 인증
# ============================================================
variable "oci_tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
}

variable "oci_user_ocid" {
  description = "OCI User OCID"
  type        = string
}

variable "oci_fingerprint" {
  description = "OCI API Key Fingerprint"
  type        = string
}

variable "oci_private_key_path" {
  description = "OCI API 개인키 경로 (절대경로)"
  type        = string
}

variable "oci_region" {
  description = "OCI 리전"
  type        = string
  default     = "ap-osaka-1"
}

# ============================================================
# OCI 리소스 OCID
# ============================================================
variable "compartment_ocid" {
  description = "Compartment OCID"
  type        = string
}

variable "subnet_ocid" {
  description = "서브넷 OCID"
  type        = string
}

variable "security_list_ocid" {
  description = "Security List OCID (oci_core_default_security_list로 관리)"
  type        = string
}

# ============================================================
# 인스턴스 스펙
# ============================================================
variable "master_ocpus" {
  description = "마스터 노드 OCPU 수"
  type        = number
  default     = 2
}

variable "master_memory_gbs" {
  description = "마스터 노드 메모리 (GB)"
  type        = number
  default     = 12
}

variable "worker_count" {
  description = "워커 노드 수"
  type        = number
  default     = 3
}

variable "worker_ocpus" {
  description = "워커 노드 OCPU 수"
  type        = number
  default     = 1
}

variable "worker_memory_gbs" {
  description = "워커 노드 메모리 (GB)"
  type        = number
  default     = 6
}

variable "ssh_public_key_path" {
  description = "SSH 공개키 경로"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
