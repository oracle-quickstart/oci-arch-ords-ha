## Copyright © 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "null_resource" "compute-script1" {
  depends_on = [oci_core_instance.compute_instance, oci_database_autonomous_database.ATPdatabase, oci_core_network_security_group_security_rule.ATPSecurityEgressGroupRule, oci_core_network_security_group_security_rule.ATPSecurityIngressGroupRules]

    count         = var.number_of_midtiers

  # Install ORDS, SQLcl and set up the firewall rules
  provisioner "remote-exec" {

    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.compute_instance[count.index].public_ip
      private_key =  tls_private_key.key.private_key_pem
      agent       = false
      timeout     = "2m"
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
      private_key = tls_private_key.key.private_key_pem
      agent       = false
      timeout     = "2m"
    }
    source      = "${path.module}/ords/ords_conf.zip"
    destination = "/home/opc/ords_conf.zip"
  }

  # ADB Wallet

  provisioner "local-exec" {
    command = "echo '${oci_database_autonomous_database_wallet.ATP_database_wallet.content}' >> ${var.ATP_tde_wallet_zip_file}_encoded"
  }

  provisioner "local-exec" {
    command = "base64 --decode ${var.ATP_tde_wallet_zip_file}_encoded > ${var.ATP_tde_wallet_zip_file}"
  }

  provisioner "local-exec" {
    command = "rm -rf ${var.ATP_tde_wallet_zip_file}_encoded"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.compute_instance[count.index].public_ip
      private_key =  tls_private_key.key.private_key_pem
      agent       = false
      timeout     = "2m"
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
      private_key = tls_private_key.key.private_key_pem
      agent       = false
      timeout     = "2m"
    }


        inline = [  
        "sudo mv /home/opc/tde_wallet*.zip /home/oracle/wallet.zip",
        "sudo chown oracle:oinstall /home/oracle/wallet.zip",
        "sudo mv /home/opc/ords_conf.zip /opt/oracle/ords/",
        "sudo chown oracle:oinstall /opt/oracle/ords/ords_conf.zip",     
        "sudo su - oracle -c 'unzip -q /opt/oracle/ords/ords_conf.zip -d /opt/oracle/ords/'",
        "sudo su - oracle -c 'sed -i 's/PASSWORD_HERE/${var.ATP_password}/g' /opt/oracle/ords/conf/ords/create_user.sql'",
        "sudo su - oracle -c 'sed -i 's/_NODE_NUMBER/${count.index}/g' /opt/oracle/ords/conf/ords/create_user.sql'",        
        "sudo su - oracle -c 'sed -i 's/PASSWORD_HERE/${var.ATP_password}/g' /opt/oracle/ords/conf/ords/conf/apex_pu.xml'",
        "sudo su - oracle -c 'sed -i 's/DATABASE_NAME_HERE/${var.ATP_database_db_name}/g' /opt/oracle/ords/conf/ords/conf/apex_pu.xml'",
        "sudo su - oracle -c 'sed -i 's/_NODE_NUMBER/${count.index}/g' /opt/oracle/ords/conf/ords/conf/apex_pu.xml'",        
        "sudo su - oracle -c 'java -jar /opt/oracle/ords/ords.war configdir /opt/oracle/ords/conf'",
        "sudo su - oracle -c 'sql -cloudconfig /home/oracle/wallet.zip admin/${var.ATP_password}@${var.ATP_database_db_name}_high @/opt/oracle/ords/conf/ords/create_user.sql'",
        "sudo su - oracle -c 'java -jar -Duser.timezone=UTC /opt/oracle/ords/ords.war standalone &'",
        ]

  }

}
