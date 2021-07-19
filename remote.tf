## Copyright © 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "null_resource" "compute-script1" {
  depends_on = [oci_core_instance.compute_instance, oci_database_autonomous_database.ATPdatabase, oci_core_network_security_group_security_rule.ATPSecurityEgressGroupRule, oci_core_network_security_group_security_rule.ATPSecurityIngressGroupRules]
  
  # Install ORDS, SQLcl and set up the firewall rules
  provisioner "remote-exec" {

    count         = var.number_of_midtiers

    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.compute_instance[count.index].public_ip
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      agent       = false
      timeout     = "10m"
    }
      inline = [
        "sudo yum install ords -y",
        "sudo yum install sqlcl -y",
        "sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp",      
        "sudo firewall-cmd --reload",
        ]
  }


  # Stage ORDS conf files
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.compute_instance[count.index].public_ip
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      agent       = false
      timeout     = "10m"
    }
    source      = "${path.module}/ords/ords_conf.zip"
    destination = "/opt/oracle/ords/"
  }

  # ADB Wallet

resource "local_file" "autonomous_data_warehouse_wallet_file" {
  content_base64 = oci_database_autonomous_database_wallet.ATP_database_wallet.content
  filename       = ${var.ATP_tde_wallet_zip_file}


  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.compute_instance[count.index].public_ip
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      agent       = false
      timeout     = "10m"
    }
    source      = var.ATP_tde_wallet_zip_file
    destination = "/home/opc/${var.ATP_tde_wallet_zip_file}"
  }


  #Configure and start ORDS
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.compute_instance[count.index].public_ip
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      agent       = false
      timeout     = "10m"
    }


        inline = [  
        "sudo su - oracle -c 'unzip -q /opt/oracle/ords/ords_conf.zip -d /opt/oracle/ords/'",
        "sudo su - oracle -c 'sed -i 's/PASSWORD_HERE/${var.ATP_password}/g' /opt/oracle/ords/conf/ords/create_user.sql'",
        "sudo su - oracle -c 'sed -i 's/PASSWORD_HERE/${var.ATP_password}/g' /opt/oracle/ords/conf/ords/conf/apex_pu.xml'",
        "sudo su - oracle -c 'sed -i 's/DATABASE_NAME_HERE/${var.ATP_database_db_name}/g' /opt/oracle/ords/conf/ords/conf/apex_pu.xml'",  
        "sudo su - oracle -c 'java -jar /opt/oracle/ords/ords.war configdir /opt/oracle/ords/conf'",
        "sudo su - oracle -c 'sql -cloudconfig /tmp/wallet.zip admin/${var.admin_password}@${var.database_name}_high @/opt/oracle/ords/conf/ords/create_user.sql'",
        "sudo su - oracle -c 'java -jar -Duser.timezone=UTC /opt/oracle/ords/ords.war standalone &'",
        ]

  }

}