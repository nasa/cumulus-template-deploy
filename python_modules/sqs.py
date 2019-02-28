import boto3
import botocore
import os
import json
from time import sleep

from cumulus_logger import CumulusLogger
logger = CumulusLogger()

def get_sqs_conn():

   default_region = os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
   return boto3.resource('sqs', region_name=default_region)

def change_visibility(msg, timeout=5):
   if not msg:
      logger.warning("I can't reset visiblit of non-SQS message: {0}".format(msg))
      return False

   try: 
      msg.change_visibility(VisibilityTimeout=timeout)
      return True
   except botocore.exceptions.ClientError as e:
      logger.warning("Could not change state of SQS message: {0}".format(e))
      return False

def get_sqs(queue_name):
   sqs = get_sqs_conn()
   for _ in range(10):
      try:
         queue = sqs.get_queue_by_name(QueueName=queue_name)
         return queue
      except botocore.exceptions.EndpointConnectionError as e:
         logger.warning("Could not connect to SQS {0}:{1}".format(queue_name, e))
         sleep(300) 

   logger.fatal("Could not connect to SQS queue: {0}".format(queue_name)) 
   return False

def get_next_message(queue):
   for message in queue.receive_messages():
       logger.debug("Received messsage: {0}".format(message.body))
       return message

def send_message(queue, message, delay=1):
   json_check = json.loads(message)
   result = queue.send_message(MessageBody=message, DelaySeconds=delay)
   return result

def delete_message(queue_url, receipt_handle):
   sqs = get_sqs_conn()
   message = sqs.Message( queue_url, receipt_handle )
   return message.delete()

