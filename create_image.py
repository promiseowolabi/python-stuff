import boto3

region = 'eu-west-1'

backup_client = boto3.client('backup', region_name=region)
efs_client = boto3.client('efs', region_name=region)
ec2_client = boto3.client('ec2', region_name=region)

def create_custom_ami(instance_id, region, *args):
    """Create an Image from an AWS backup recovery point and choose specific volumes snapshots.
    Arguments:
        instance_id {str} -- The instance_id of the EC2 instance.
        region {str} -- The region in use
        *args {str} -- One or more block devices to use in creating the new image (AMI)
    """
    # Get Instance data with describe_instances
    instance = ec2_client.describe_instances(InstanceIds=[instance_id])
    owner_id = instance['Reservations'][0]['OwnerId']    # Get account ID
    block_device_mapping = instance['Reservations'][0]['Instances'][0]['BlockDeviceMappings']    # Get block device mapping list of dict
    device_map_set = set()
    args_set = set()
    root_set = {instance['Reservations'][0]['Instances'][0]['RootDeviceName']}    # Get root device name
    for dev in block_device_mapping:    # Create a set with block device names attached to the instance
        device_map_set.add(dev['DeviceName'])
    for arg in args:    # Create a set with block device name arguments, required for AMI
        args_set.add(arg)
    args_set = args_set - root_set    # Remove root device name from arguments
    exclude = (device_map_set - root_set) - args_set    # Set with excluded block device names
    tags = instance['Reservations'][0]['Instances'][0]['Tags']    # Get instance Tags
    instance_name = None
    for tag in tags:
        if tag['Key'] == 'Name':
            instance_name = tag['Value']
    if not instance_name:
        instance_name = instance_id    
    if device_map_set.issuperset(args_set):    # Check if the block devices in args are attached to the instance
        BlockDeviceMappings = []
        resource_arn = 'arn:aws:ec2:'+region+':'+owner_id+':instance/'+instance_id
        rp_arn_list = backup_client.list_recovery_points_by_resource(ResourceArn=resource_arn)    # Get the recent recovery points from AWS Backup for Instance
        ami = rp_arn_list['RecoveryPoints'][0]['RecoveryPointArn'].split('/')[1]    # Get AMI
        # Get all the snapshots created for this AMI
        snapshots = ec2_client.describe_snapshots(
            Filters=[{'Name': 'description',
                      'Values': ['Created by CreateImage('+instance_id+') for '+ami]}])
        # Add BlockDeviceMappings for args
        for arg in args_set:
            for vol in block_device_mapping:
                if arg == vol['DeviceName']:
                    for vol_id in block_device_mapping:
                        for snap in snapshots['Snapshots']:
                            if snap['VolumeId'] == vol_id['Ebs']["VolumeId"] and arg == vol_id['DeviceName']:
                                BlockDeviceMappings.append(
                                    {'DeviceName': arg,
                                     'Ebs': {'SnapshotId': snap['SnapshotId']}}
                                )
        # Removing BlockDeviceMappings for excluded devices
        for excl in exclude:
            BlockDeviceMappings.append({'DeviceName': excl, 'Ebs': {}, 'NoDevice': ''})
        # Creating Image
        response = ec2_client.create_image(
            BlockDeviceMappings=BlockDeviceMappings,
            Description='This image is created by a Custom CreateImage Script',
            InstanceId=instance_id,
            Name='Custom_AMI_'+instance_id,
            NoReboot=True,
            TagSpecifications=[
                {'ResourceType': 'image',
                 'Tags': [{'Key': 'Name', 'Value': instance_name}]
                },
            ]
        )
        return response
    else:
        return print('Wrong devices: {}'.format(args))


# Example

custom_ami = create_custom_ami('i-0123456789', 'eu-west-1', '/dev/sdf', '/dev/xvda')
custom_ami