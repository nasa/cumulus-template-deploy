from jinja2 import Template

template_file = 'echo10.granule.xml.template'
with open(template_file, 'r') as t:
   template_text = t.read()

echo10_template = Template(template_text)

template_object = { 
  'granuleur': 'SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202-SLC_METADATA',
  'insert_time': '2019-02-26T08:39:14Z',
  'last_update': '2019-02-26T08:39:14Z',
  'datasetid': 'SIR-C_SLC_METADATA',
  'product_size_mb': 1.0,
  'product_name': 'SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202',
  'start_time': '1994-04-09T11:05:00Z',
  'end_time': '1994-04-09T11:10:00Z',
  'boundingbox': [ [ [19.238, -111.6512], [19.6319,-110.6602], [18.7734,-110.3003],[18.3807,-111.2851]]],
  'revolution': 88,
  'platforms': [ { 'platform_name': 'STS', 'instrument_name': 'SIR-C/X-SAR', 'sensor_short_name': 'X-SAR'} ],
  #'online_access_url': 'https://datapool.asf.alaska.edu/SLC/SI/SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202.zip',
  'online_access_url': 'https://datapool.asf.alaska.edu/SLC/SI/SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202.xml',
  'orderable': 'true',
  'visible': 'true',
  #'browse_url': 'https://datapool.asf.alaska.edu/BROWSE/SI/SIRC1_11_SLC_ALL_088_040_08_19940414T202148_19940414T202202_browse.png' 
}
  

echo10_xml = echo10_template.render(template_object)
print (echo10_xml)
