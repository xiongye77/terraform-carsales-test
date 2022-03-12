import json
import boto3
from botocore.exceptions import ClientError
import logging
import os

AWS_REGION = "ap-southeast-2"
ec2_client = boto3.client('ec2', region_name = AWS_REGION)
ssm = boto3.client('ssm', region_name = AWS_REGION)

def compare_and_change():
    launch_templates = ec2_client.describe_launch_templates(LaunchTemplateNames=['carsales-lt'])
    latest_version = launch_templates['LaunchTemplates'][0]['LatestVersionNumber']
    parameter = ssm.get_parameter(Name='ASG_launch_template_version')
    ssm_value=parameter['Parameter']['Value']
    if int(ssm_value) != int(latest_version):
        print ("change ssm")
        ssm.put_parameter(Name='ASG_launch_template_version',Value=str(latest_version),Type='String',Overwrite=True)
        print ("after change version is {} ".format(latest_version))
    else:
        print (" version are same no need change")

def lambda_handler(event, context):

    compare_and_change()
    return {
        'statusCode': 200,
        'body': json.dumps('compare and change finished')
    }
