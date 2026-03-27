# ============================================================
# 데이터 소스
# ============================================================

# Ubuntu 24.04 ARM 이미지 자동 조회
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Availability Domain 조회
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

locals {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  image_ocid          = data.oci_core_images.ubuntu_arm.images[0].id
  ssh_public_key      = file(pathexpand(var.ssh_public_key_path))
  cloud_init          = base64encode(file("${path.module}/../scripts/cloud-init.sh"))
}

# ============================================================
# 마스터 노드
# ============================================================
resource "oci_core_instance" "master" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain
  display_name        = "k8s-master"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.master_ocpus
    memory_in_gbs = var.master_memory_gbs
  }

  source_details {
    source_type = "image"
    source_id   = local.image_ocid
  }

  create_vnic_details {
    subnet_id        = var.subnet_ocid
    assign_public_ip = true
    display_name     = "k8s-master-vnic"
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data           = local.cloud_init
  }

  freeform_tags = {
    role    = "master"
    cluster = "k8s"
  }
}

# ============================================================
# 워커 노드 (count로 3대)
# ============================================================
resource "oci_core_instance" "workers" {
  count               = var.worker_count
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain
  display_name        = "k8s-worker-${count.index}"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.worker_ocpus
    memory_in_gbs = var.worker_memory_gbs
  }

  source_details {
    source_type = "image"
    source_id   = local.image_ocid
  }

  create_vnic_details {
    subnet_id        = var.subnet_ocid
    assign_public_ip = true
    display_name     = "k8s-worker-${count.index}-vnic"
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data           = local.cloud_init
  }

  freeform_tags = {
    role    = "worker"
    cluster = "k8s"
    index   = tostring(count.index)
  }
}
