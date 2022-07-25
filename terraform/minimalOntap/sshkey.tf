resource "tls_private_key" "privkey" {
  algorithm = "RSA"
}

resource "aws_key_pair" "benchmark-key-pair" {
  key_name   = "terraform_benchmark"
  public_key = tls_private_key.privkey.public_key_openssh

  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = "rm -f ./myKey.pem; echo '${tls_private_key.privkey.private_key_pem}' > ./myKey.pem"
  }

  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = "chmod 400 myKey.pem"
  }
}
