import json
import urllib.parse
import boto3
import os
import sys
import uuid
from urllib.parse import unquote_plus
import tempfile

print('Loading function')

s3 = boto3.client('s3')

scality = boto3.client(
    's3',
    aws_access_key_id = os.environ['aws_access_key_id'],
    aws_secret_access_key = os.environ['aws_secret_access_key'],
    endpoint_url = os.environ['endpoint_url']
    )


def lambda_handler(event, context):
    #print("Received event: " + json.dumps(event, indent=2))

    # Get the object from the event 
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = unquote_plus(event['Records'][0]['s3']['object']['key'])
    tmpkey = key.replace('/', '')
    download_path = os.path.join(tempfile.gettempdir(), "{}{}".format(uuid.uuid4(), tmpkey))

    print("Downloading object from S3")
    try:
        s3.download_file(bucket, key, download_path)
        print("Success downloading object from S3")
    except Exception as e:
        print(e)
        print('Error getting object {} from bucket {}. Make sure they exist and your bucket is in the same region as this function.'.format(key, bucket))
        raise e
    print("Uploading to scality object store")
    scality.upload_file(download_path,'{}-copy'.format(bucket), key)
    print("Completed upload to scality object store")
    
    
