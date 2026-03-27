output "master_public_ip" {
  description = "마스터 노드 Public IP"
  value       = oci_core_instance.master.public_ip
}

output "worker_public_ips" {
  description = "워커 노드 Public IP 목록"
  value       = [for w in oci_core_instance.workers : w.public_ip]
}

output "all_ips" {
  description = "전체 노드 IP 요약"
  value = {
    master  = oci_core_instance.master.public_ip
    workers = [for w in oci_core_instance.workers : w.public_ip]
  }
}
