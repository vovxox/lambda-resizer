#!/usr/bin/python
# -*- coding: utf-8 -*-
import boto3, json, logging
from botocore.client import Config
from botocore.exceptions import ClientError

# Set the global variables
"""
Can Override the global variables using Lambda Environment Parameters

CORS
https://www.netskope.com/blog/cors-exploitation-in-the-cloud

CORS WHITELIST
https://stackoverflow.com/questions/56729173/aws-lambda-domain-whitelist
"""
globalVars = {}
globalVars["GetDefaultExpiry"] = "10"
globalVars["PostDefaultExpiry"] = "60"

logger = logging.getLogger()

s3 = boto3.client(
    "s3", region_name="ap-southeast-2", config=Config(signature_version="s3v4")
)


def signed_get_url(event):
    """Function to generate the presigned GET url, that can be used to retrieve objects from s3 bucket
    Required Bucket Name and Object Name to generate url
    """
    bodyData = json.loads(event["body"])
    try:
        url = s3.generate_presigned_url(
            ClientMethod="get_object",
            Params={"Bucket": bodyData["BucketName"], "Key": bodyData["ObjectName"]},
            ExpiresIn=int(globalVars["GetDefaultExpiry"]),
        )
        # Browser requires this header to allow cross domain requests
        head = {"Access-Control-Allow-Origin": "*"}
        body = {"PreSignedUrl": url, "ExpiresIn": globalVars["GetDefaultExpiry"]}
        response = {"statusCode": 200, "body": json.dumps(body), "headers": head}
    except Exception as e:
        logger.error("Unable to generate URL")
        logger.error("ERROR: {0}".format(str(e)))
        response = {
            "statusCode": 502,
            "body": "Unable to generate URL",
            "headers": head,
        }
        pass
    return response


def signed_post_url(event):
    """Function to generate the presigned post url, that can be used to upload objects to s3 bucket
    Required Bucket Name and Object Name to generate url
    """
    import uuid

    bodyData = json.loads(event["body"])
    # Add random prefix - Although not necessary to improve s3 performance, to avoid overwrite of existing objects.
    fName = uuid.uuid4().hex + "_" + bodyData["FileName"]
    try:
        post = s3.generate_presigned_post(
            Bucket=bodyData["BucketName"],
            Key=fName,
            ExpiresIn=int(globalVars["PostDefaultExpiry"]),
        )
        # Browser requires this header to allow cross domain requests
        head = {"Access-Control-Allow-Origin": "*"}
        post["ExpiresIn"] = globalVars["PostDefaultExpiry"]
        response = {"statusCode": 200, "body": json.dumps(post), "headers": head}
    except Exception as e:
        logger.error("Unable to generate PUT Url")
        logger.error("ERROR: {0}".format(str(e)))
        response = {
            "statusCode": 502,
            "body": "Unable to generate URL",
            "headers": head,
        }
        pass
    return response


def handler(event, context):
    if event["body"]:
        # Lets convert the post body back into a dictionary
        bodyData = json.loads(event["body"])

        if bodyData["methodType"] == "GET":
            response = signed_get_url(event)
        elif bodyData["methodType"] == "POST":
            response = signed_post_url(event)
        else:
            body = {
                "Message": "Unable to generate URL, Re-Check your Bucket/Object Name"
            }
            head = {"Access-Control-Allow-Origin": "*"}
            response = {"statusCode": 403, "body": json.dumps(body), "headers": head}
    return response
