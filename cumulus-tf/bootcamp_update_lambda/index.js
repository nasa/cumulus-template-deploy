'use strict';

const { runCumulusTask } = require('@cumulus/cumulus-message-adapter-js');
const log = require('@cumulus/common/log');

/**
 * Return payload object: {
 *   input: payload from previous lambda,
 *   buckets: buckets object from `config` CMA object
 * }
 *
 * @param {Object} event - input from the message adapter
 * @returns {Object} sample JSON object
 */
async function bootcampExample(event) {
  return {
    inputKey: event.config.someKey,
    buckets: event.config.buckets,
    input: event.input,
  };
}
/**
 * Lambda handler
 *
 * @param {Object} event      - a Cumulus Message
 * @param {Object} context    - an AWS Lambda context
 * @returns {Promise<Object>} - sample JSON object
 */
async function handler(event, context) {
  return runCumulusTask(bootcampExample, event, context);
}

exports.handler = handler;
