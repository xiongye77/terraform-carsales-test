import boto3
import logging
import os
from botocore.exceptions import ClientError
import logging
import json
asg_client = boto3.client('autoscaling')

def start_asg_instance_refresh(asg_name):
    try:
        logging.info("Starting Web Server Autoscaling group refresh.")
        response = asg_client.start_instance_refresh(
                     AutoScalingGroupName=asg_name,
                     Strategy='Rolling',
                     Preferences={
                                'MinHealthyPercentage': 90,
                                'InstanceWarmup': 60  ##1 min to wait before next replacement.
                     })
        logging.info("Instance refresh successfully triggered.")
    except ClientError as exp:
        logging.error("Error occured during instance refresh start.")
        raise exp


def lambda_handler(event, context):
    #asg_name = 'carsales_auto_scaling_group'
    asg_name = os.environ['ASGName']
    start_asg_instance_refresh(asg_name)
    return {
        'statusCode': 200,
        'body': json.dumps('Instance Refresh Lambda is Successful.')
    }
