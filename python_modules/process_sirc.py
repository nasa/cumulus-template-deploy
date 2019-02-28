import boto3
import datetime
from jinja2 import Template
from botocore.exceptions import ClientError

from run_cumulus_task import run_cumulus_task
from cumulus_logger import CumulusLogger

# Local path to echo10 granule jinja2 template
template_file = 'echo10.granule.xml.template'

# Some Py2/Py3 Compatability
try:
    from json.decoder import JSONDecodeError
except:
    JSONDecodeError = ValueError

# instantiate CumulusLogger
logger = CumulusLogger()

'''
(INPUT) Queued Granule Message

{
  "files": [ {
      "bucket": "sirc-e5orlnb7-internal", 
      "object": "SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202.zip", 
      "size": 3656222107, 
      "type": "SLC"
    },{
      "bucket": "sirc-e5orlnb7-internal", 
      "object": "SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202.xml", 
      "size": 6544, 
      "type": "metadata"
    },{
      "bucket": "sirc-e5orlnb7-internal", 
      "object": "SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202_browse.png", 
      "size": 123456, 
      "type": "browse"
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

(OUTPUT) report-to-cmr Message

{ 
  "granules": [ 
    {
      "granuleId": "SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202.zip",
      "files": [ {
         "bucket": "sirc-e5orlnb7-protected", 
         "name": "SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202.zip", 
         "filename": "s3://sirc-e5orlnb7-protected/SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202.zip"
       } ],
    }, {
      "granuleId": "SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202.xml",
      "files": [ {
         "bucket": "sirc-e5orlnb7-public"
         "name": "SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202_browse.xml",
         "filename": "s3://sirc-e5orlnb7-public/SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202.xml"
       } ]
    }
  ]
}


'''

def granule_to_date(name, offset):
    return "{0}-{1}-{2}T{3}:{4}:{5}Z".format(
       name[offset+0:offset+4],
       name[offset+4:offset+6],
       name[offset+6:offset+8],
       name[offset+9:offset+11],
       name[offset+11:offset+13],
       name[offset+13:offset+15])

def generate_echo10(granule, datasetid, file_obj, browse):

    with open(template_file, 'r') as t:
         template_text = t.read()

    echo10_template = Template(template_text)

    # Annoyingly complex bounding box construction
    boundingbox = [ [ granule['lat_start_near_range'], granule['lon_start_near_range'] ],
                    [ granule['lat_start_far_range'], granule['lon_start_far_range'] ],
                    [ granule['lat_end_far_range'], granule['lon_end_far_range'] ],
                    [ granule['lat_end_near_range'], granule['lon_end_near_range'] ] ]

    template_object = {
      'granuleur': "{0}-{1}".format(granule['name'], file_obj['type'].upper()),
      'insert_time': datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"),
      'last_update': datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"),
      'datasetid': datasetid,
      'product_size_mb': file_obj['size'],
      'product_name': granule['name'],
      'start_time': granule_to_date(granule['name'], 28),
      'end_time': granule_to_date(granule['name'], 44),
      'boundingbox': boundingbox,
      'revolution': granule['orbit'],
      'platforms': [ { 'platform_name': 'STS', 'instrument_name': 'SIR-C/X-SAR', 'sensor_short_name': 'X-SAR'} ],
      'online_access_url': '{0}{1}/SI/{2}'.format('https://datapool.asf.alaska.edu/', file_obj['type'].upper(), file_obj['object']),
      'orderable': 'true', 'visible': 'true',
      'browse_url': '{0}/{2}'.format('https://datapool.asf.alaska.edu/BROWSE/SI/',browse) 
    }

    return echo10_template.render(template_object)


def task(event, context):

    # Steps:  
    #  1) Move files to "home" bucket
    #  2) Generate [granule].cmr.xml
    #  3) generate output payload for report-to-cmr

    s3 = boto3.resource('s3')

    rec = event["input"]

    if 'SLC' in rec["granuleId"]:
       data_type = 'SLC'
    else:
       data_type = 'GRD' # Should this be GRD?!

    # Collection Metadata from app/config
    cm = event["config"]["collections"]
    bucket_map = event["config"]["buckets"]

    # delete after we've copied EVERYTHING
    post_copy_deletes = []

    # move the files
    for sfile in rec["files"]:
       copy_source = { 'Bucket': sfile['bucket'], 'Key': sfile['object'] }
       sfile_bucket_class = cm["types"][sfile['type']]
       destination = bucket_map[sfile_bucket_class]['name']
       logger.info("Copying s3://{0}/{1} to {2} bucket s3://{3}".format(sfile['bucket'], sfile['object'], sfile_bucket_class, destination))
 
       try: 
          s3.meta.client.copy(copy_source, destination, sfile['object'])
       except ClientError as E:
          logger.fatal("Unable to copy s3://{0}/{1} to {2}: {3}".format(sfile['bucket'], sfile['object'], destination, E))
          raise(E) 

       # Update the record
       sfile['bucket'] = destination
 
       post_copy_deletes.append(copy_source)

    # Files we want to report to CMR
    cmr_grans = []

    # Generate the Product Record 
    browse_name = next((item for item in rec["files"] if item['type'] == 'BROWSE'), None)['object']
    product_file = next((item for item in rec["files"] if item['type'] == data_type), None)
    product_xml = generate_echo10( rec["metadata"], data_type, product_file, browse_name )
    product_cmr_xml = "{0}.cmr.xml".format(product_file['object'])

    # Write it out
    try: 
       logger.info("Writing out Product Echo10 XML for CMR: {0}".format(product_cmr_xml))
       s3.Object(product_file['bucket'], "{0}.cmr.xml".format(product_file['object'])).put(Body=product_xml)
    except ClientError as E:
       logger.fatal("Unable to write Product Echo10 XML out to S3: {0}".format(E))
       raise (E)
  
    # Record to send to post-to-cmr
    cmr_grans.append( { "granuleId": product_file['object'],
                        "files": { 'bucket': product_file['bucket'], 'name': product_file['object'],
                                   'filename': 's3://{0}/{1}'.format( product_file['bucket'], product_file['object'])}})

    # Generate the Metadata record:
    metadata_file = next((item for item in rec["files"] if item['type'] == 'METADATA'), None)
    metadata_xml = generate_echo10( rec["metadata"], "{0}_METADATA".format(data_type), metadata_file, browse_name)
    metadata_cmr_xml = "{0}.cmr.xml".format(metadata_file['object'])
   
    # Write it out 
    try:
       logger.info("Writing out Metadata Echo10 XML for CMR: {0}".format(metadata_cmr_xml))
       s3.Object(metadata_file['bucket'], "{0}.cmr.xml".format(metadata_file['object'])).put(Body=metadata_xml)
    except ClientError as E:
       logger.fatal("Unable to write Metadata Echo10 XML out to S3: {0}".format(E))
       raise (E)
      
    cmr_grans.append( { "granuleId": metadata_file['object'],
                        "files": { 'bucket': metadata_file['bucket'], 'name': metadata_file['object'],
                        'filename': 's3://{0}/{1}'.format( metadata_file['bucket'], metadata_file['object'] )}})

    # Remove it after succesful ingest
    for obj in post_copy_deletes:
        logger.info("Removing ingested/copied file s3://{0}/{1}".format(obj['Bucket'], obj['Key']))
        s3.Object(obj['Bucket'], obj['Key']).delete()
  
    # Everything is as should be, now return the object to go to report-to-cmr
    return { "granules": cmr_grans }
    

# Handler for ProcessSircGranule Lambda
def handler(event, context):
    logger.setMetadata(event, context)
    return run_cumulus_task(task, event, context)

