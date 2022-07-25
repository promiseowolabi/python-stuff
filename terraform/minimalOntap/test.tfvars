#main_box_instance_type = "t2.micro"
main_box_instance_type = "i3en.2xlarge" # this has two local disks
#main_box_instance_type = "i3en.24xlarge"


ontapSize = 1024
#ontapThroughput = 128  # Why this is not allowed
ontapThroughput = 512
ontapIOPS       = 3072