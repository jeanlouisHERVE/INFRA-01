import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')

    # Get all running instances
    response = ec2.describe_instances(
        Filters=[
            {
                'Name': 'instance-state-name',
                'Values': ['running']
            }
        ]
    )

    instance_ids = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])

    if not instance_ids:
        print("No running instances found.")
        return

    print(f"Stopping instances: {instance_ids}")
    ec2.stop_instances(InstanceIds=instance_ids)
    print("Instances stopped successfully.")