output "sql-developer_Web_URL" {
  value = "http://${oci_load_balancer.lb1.ip_addresses[0]}/ords/sql-developer"
}

output "SSH_PRIVATE_KEY" { value = "${tls_private_key.key.private_key_pem}" }

output "SSH_PUBLIC_KEY" { value = "${tls_private_key.key.public_key_openssh}" }