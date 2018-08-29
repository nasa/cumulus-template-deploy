'use strict';

const cumulusMessageAdapter = require('@cumulus/cumulus-message-adapter-js');
const { log } = require('@cumulus/common');
const { generateCmrFilesForGranules } = require('@cumulus/integration-tests');

/**
 * Given an S3 URL, returns a file object of { name, bucket }
 *
 * @param {Object} url - the S3 URL
 * @returns {Object} the file object
 */
function s3UrlToFile(url) {
  const match = url.match(/s3:\/\/([^\/]+)\/(.*)/);
  return {
    bucket: match[1],
    name: match[2]
  };
}

/**
* Return metadata to submit to CMR for an SE TIM example
*
* @param {Object} event - input from the message adapter
* @returns {Object} example metadata
*/
async function exampleMetadata(event) {
  const config = event.config;
  const stack = config.stack;
  const bucket = config.bucket;
  const key = config.key;
  const collection = config.collection;

  const granule = {
    granuleId: `MODSETIM-${stack}`,
    files: [{ filename: `s3://${bucket}/${key}`, fileStagingDir: `${stack}-metadata` }]
  };

  const metadataFiles = await generateCmrFilesForGranules([granule], collection, bucket);

  const files = metadataFiles.map((f) => {
    const s3Info = s3UrlToFile(f);
    return {
      filename: f,
      name: s3Info.name,
      bucket: s3Info.bucket
    };
  });

  return {
    granules: [{
      granuleId: granule.granuleId,
      files: files
    }]
  };
}
/**
* Lambda handler
*
* @param {Object} event - a Cumulus Message
* @param {Object} context - an AWS Lambda context
* @param {Function} callback - an AWS Lambda handler
* @returns {undefined} - does not return a value
*/
function handler(event, context, callback) {
  cumulusMessageAdapter.runCumulusTask(exampleMetadata, event, context, callback);
}

exports.handler = handler;
