# ============================================================
# OCI 인증 정보 — 민감정보, .gitignore에 추가 권장
# ============================================================
oci_tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaaetkpf47clf5mi3gov4dukxunlawavpytaco7s7kitb6557vixima"
oci_user_ocid        = "ocid1.user.oc1..aaaaaaaaumvnfjpsptswqjedzg3ec6klbometbelivo7zsfatzxfsc3ag4eq"
oci_fingerprint      = "40:96:e3:5d:d0:e6:d6:a7:1e:f6:4e:2d:07:52:0a:34"
oci_private_key_path = "C:/Users/anvi/.oci/ohsimon1001@gmail.com-2026-03-26T00_58_18.676Z.pem"
oci_region           = "ap-osaka-1"

# ============================================================
# OCI 리소스 OCID
# ============================================================
compartment_ocid   = "ocid1.tenancy.oc1..aaaaaaaaetkpf47clf5mi3gov4dukxunlawavpytaco7s7kitb6557vixima"
subnet_ocid        = "ocid1.subnet.oc1.ap-osaka-1.aaaaaaaacza5vru4abdrfbiu75rjpg6krzz4ylnzdan5hcyhvwjtuw576mra"
security_list_ocid = "ocid1.securitylist.oc1.ap-osaka-1.aaaaaaaa3v263i4ruibfbeipulzoy7ofh7ipu4ggt3afvpvhpqqktghe5lca"

# ============================================================
# 인스턴스 스펙 (기본값 사용 시 생략 가능)
# ============================================================
master_ocpus      = 2
master_memory_gbs = 12
worker_count      = 3
worker_ocpus      = 1
worker_memory_gbs = 6
