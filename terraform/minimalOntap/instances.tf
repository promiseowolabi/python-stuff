data "template_cloudinit_config" "master" {
  gzip          = true
  base64_encode = true


  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.setupONTAP.rendered
  }
}

resource "aws_instance" "app_server" {
  ami = "ami-04dd4500af104442f" # Amazon linux 2
  #  ami                    = "ami-0b0af3577fe5e3532"   # Red Hat Enterprise Linux 8
  instance_type          = var.main_box_instance_type
  subnet_id              = aws_subnet.primary.id
  vpc_security_group_ids = [aws_security_group.ssh-allowed.id, aws_security_group.ontap.id]

  key_name  = aws_key_pair.benchmark-key-pair.key_name
  user_data = data.template_cloudinit_config.master.rendered

  tags = {
    Name = var.name
  }

  depends_on = [aws_fsx_ontap_volume.vol]

}

