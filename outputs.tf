## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output "sql-developer_Web_URL" {
  value = "http://${oci_load_balancer.lb1.ip_addresses[0]}/ords/sql-developer"
}

output "SSH_PRIVATE_KEY" {
  value     = tls_private_key.key.private_key_pem
  sensitive = true
}

output "SSH_PUBLIC_KEY" {
  value     = tls_private_key.key.public_key_openssh
  sensitive = true
}
