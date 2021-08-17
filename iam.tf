## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "local_file" "key_file" {
  filename = "${path.module}/key.pem"
  content  = tls_private_key.key.private_key_pem
}
