import os
import boto3
import sqs
import json
from urlparse import urlparse
from botocore.exceptions import ClientError

from run_cumulus_task import run_cumulus_task
from cumulus_logger import CumulusLogger

# Some Py2/Py3 Compatability
try:
    from json.decoder import JSONDecodeError
except:
    JSONDecodeError = ValueError

# instantiate CumulusLogger
logger = CumulusLogger()

def read_task(event, context):
    logger.info('Checking SQS for Work')

    ingest_queue_name = os.getenv('INGEST_QUEUE')

    if not ingest_queue_name:
        logger.fatal('No Ingest Queue supplied via ENV{INGEST_QUEUE}')
        
    ingest_queue = sqs.get_sqs(ingest_queue_name)
    if not ingest_queue:
        logger.fatal('There was a problem reading QUEUE {0}'.format(ingest_queue))
   
    # Check for work 
    message = sqs.get_next_message(ingest_queue)
    if message:
        json_message = message.body
        try:
            message_body = json.loads(json_message)
        except JSONDecodeError as e:
            logger.error("Could not decode JSON message {0}".format(json_message))
            logger.error(e)
            logger.warning("Releasing message back to queue")
            sqs.change_visibility(message, 600)

        cumulus_format_granule = decode_json_to_cumulus(json_message)
 
        # Append message id to enable later deletes 
        cumulus_format_granule["message_source"] = {
          "receipt_handle": message.receipt_handle, 
          "queue_url": message.queue_url
        }

        # Return cumulus message
        return cumulus_format_granule
         

    # return if there is no work
    logger.info("No more work found in queue {0}".format(ingest_queue))
    return { "STATE": "No Work Found","OBJECTS":0}

def delete_task(event, context):
    message = event["input"]["message_source"]
    logger.info('Found complete task to remove from queue: {0}'.format(message))
    try: 
        sqs.delete_message(message["queue_url"], message["receipt_handle"])
    except ClientError as E:
        logger.fatal("Unable to delete message {0}: {1}".format(message, E))
        raise(E)

    return { "STATE": "Delete Successful!" }
 
'''

> decode_json_to_cumulus( ... ) IN/OUT:
 
(INPUT) ingest json_message format:

{
  "products": {
    "BROWSE": "s3://sirc-e5orlnb7-internal/SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202_browse.png", 
    "SLC": "s3://sirc-e5orlnb7-internal/SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202.zip", 
    "METADATA": "s3://sirc-e5orlnb7-internal/SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202.xml"
  },
  "metadata": {
    "acquisition_date": "08_19940414T202", 
    "antenna_pattern_correction_cutoff": "1520", 
      ...
    "y_pixel_size": "4.8841", 
    "yaw": "-0.24192"
  }
}

(OUTPUT) queue-granule message format:

{
  "granules": [ {
      "files": [ {
          "bucket": "sirc-e5orlnb7-internal", 
          "object": "SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202.zip", 
          "size": 3656222107, 
          "type": "SLC"
        },{
          "bucket": "sirc-e5orlnb7-internal", 
          "object": "SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202.xml", 
          "size": 6544, 
          "type": "METADATA"
        },{
          "bucket": "sirc-e5orlnb7-internal", 
          "object": "SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202_browse.png", 
          "size": 123456, 
          "type": "BROWSE"
        }],
      "granuleId": "SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202", 
      "metadata": {
        "acquisition_date": "08_19940414T202", 
        "antenna_pattern_correction_cutoff": "1520", 
          ...
        "y_pixel_size": "4.8841", 
        "yaw": "-0.24192"
      }
    }
  ], 
  "message_source": {
    "receipt_handle": "1234456767767", 
    "queue_url": "arn://......./ingest_queue"
  }
}
'''

def decode_json_to_cumulus(json_message):

    # Blank message
    queue_message = {"granules": [ { "files": [] } ] }

    # Copy in metadata
    queue_message["granules"][0]["metadata"] = json_message["metadata"]
    queue_message["granules"][0]["granuleId"] = json_message["metadata"]["name"]

    logger.info("Processing granule {0}".format(json_message["metadata"]["name"]))

    objects=0

    # Copy in the files
    for product in json_message['products']:
         
        url = urlparse(json_message['products'][product])
        product_file = { "bucket": url.netloc, "object": url.path, "type": product }

        try:
            # Validate that the file actually exists. 
            s3_object = boto3.resource('s3').Bucket(product_file["bucket"]).Object(product_file["object"])
            product_file["size"] = s3_object.content_length
        except ClientError as E:
            logger.error("Problem validating object {0}: {1}".format(json_message['products'][product], E))
            raise(E)

        # Add file to queue message
        logger.info("Found product file: {0}".format(product_file))
        queue_message["granules"][0]["files"].append( product_file )

        objects += 1

    queue_message["OBJECTS"] = objects

    return queue_message

# Handler for ReadEvent Lambda
def read_handler(event, context):
    logger.setMetadata(event, context)
    return run_cumulus_task(read_task, event, context)

# Handler for DeleteEvent Lambda
def delete_handler(event, context):
    logger.setMetadata(event, context)
    return run_cumulus_task(delete_task, event, context)
