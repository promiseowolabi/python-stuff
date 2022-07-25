resource "aws_security_group" "ontap" {
  name        = "ontap"
  description = "Allows mounting FSx NetAPP ONTAP"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self = true
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    self = true
  }
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "udp"
    self = true
  }

  ingress {
    from_port   = 111
    to_port     = 111
    protocol    = "tcp"
    self = true
  }
  ingress {
    from_port   = 111
    to_port     = 111
    protocol    = "udp"
    self = true
  }
  ingress {
    from_port   = 635
    to_port     = 635
    protocol    = "tcp"
    self = true
  }
  ingress {
    from_port   = 635
    to_port     = 635
    protocol    = "udp"
    self = true
  }

  ingress {
    from_port   = 4045
    to_port     = 4046
    protocol    = "tcp"
    self = true
  }
  ingress {
    from_port   = 4045
    to_port     = 4046
    protocol    = "udp"
    self = true
  }

# not just NFS
#  ingress {
#    from_port   = 11104
#    to_port     = 11105
#    protocol    = "tcp"
#    self = true
#  }
#
#  ingress {
#    from_port   = 135
#    to_port     = 135
#    protocol    = "tcp"
#    self = true
#  }
#  ingress {
#    from_port   = 135
#    to_port     = 135
#    protocol    = "udp"
#    self = true
#  }
#
#  ingress {
#    from_port   = 137
#    to_port     = 137
#    protocol    = "udp"
#    self = true
#  }
#
#  ingress {
#    from_port   = 139
#    to_port     = 139
#    protocol    = "tcp"
#    self = true
#  }
#  ingress {
#    from_port   = 139
#    to_port     = 139
#    protocol    = "udp"
#    self = true
#  }
#
#  ingress {
#    from_port   = 161
#    to_port     = 162
#    protocol    = "tcp"
#    self = true
#  }
#  ingress {
#    from_port   = 161
#    to_port     = 162
#    protocol    = "udp"
#    self = true
#  }
#
#  ingress {
#    from_port   = 3260
#    to_port     = 3260
#    protocol    = "tcp"
#    self = true
#  }
#
#  ingress {
#    from_port   = 4049
#    to_port     = 4049
#    protocol    = "udp"
#    self = true
#  }
#
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self = true
  }
#
#  ingress {
#    from_port   = 445
#    to_port     = 445
#    protocol    = "tcp"
#    self = true
#  }
#
#  ingress {
#    from_port   = 749
#    to_port     = 749
#    protocol    = "tcp"
#    self = true
#  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    self = true
  }
}

resource "aws_fsx_ontap_file_system" "fast" {
  storage_capacity                = var.ontapSize
  subnet_ids                      = [aws_subnet.primary.id, aws_subnet.secondary.id]
  security_group_ids              = [aws_security_group.ontap.id]
  throughput_capacity             = var.ontapThroughput
  preferred_subnet_id             = aws_subnet.primary.id
  automatic_backup_retention_days = 0
  deployment_type                 = "MULTI_AZ_1"
  route_table_ids                 = [aws_route_table.rt.id]

  disk_iops_configuration {
    iops = var.ontapIOPS
    mode = "USER_PROVISIONED"
  }
}

resource "aws_fsx_ontap_storage_virtual_machine" "vm" {
  file_system_id = aws_fsx_ontap_file_system.fast.id
  name           = var.name
}

resource "aws_fsx_ontap_volume" "vol" {
  name                       = "vol"
  junction_path              = "/vol"
  size_in_megabytes          = var.ontapSize
  storage_efficiency_enabled = false
  storage_virtual_machine_id = aws_fsx_ontap_storage_virtual_machine.vm.id
}

data "template_file" "setupONTAP" {
  template = file("./setupONTAP.sh.tpl")

  vars = {
    dnsname = aws_fsx_ontap_storage_virtual_machine.vm.endpoints.0.nfs.0.dns_name
    volpath = aws_fsx_ontap_volume.vol.junction_path
  }
}

