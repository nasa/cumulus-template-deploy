resource "aws_lambda_function" "atl03_extract_browse" {
  function_name    = "${var.prefix}-browse-imagery-atl03"
  filename         = "${path.module}/../lambdas/lambda-browse-imagery-from-hdf5/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambdas/lambda-browse-imagery-from-hdf5/lambda.zip")
  handler          = "ingest_granule_ATL03.lambda_handler"
  role             = module.cumulus.lambda_processing_role_arn
  runtime          = "python3.6"
  timeout          = 60

  layers = [var.cumulus_message_adapter_lambda_layer_arn]

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.no_ingress_all_egress.id]
  }
}

module "discover_granules_workflow" {
  source = "https://github.com/nasa/cumulus/releases/download/v1.19.0/terraform-aws-cumulus-workflow.zip"

  prefix          = var.prefix
  name            = "DiscoverGranules"
  workflow_config = module.cumulus.workflow_config
  system_bucket   = var.system_bucket
  tags            = local.tags

  state_machine_definition = <<JSON
{
  "Comment": "Taken from for Browse Generation Data Cookbook",
  "StartAt": "DiscoverGranules",
  "TimeoutSeconds": 18000,
  "States": {
    "DiscoverGranules": {
      "Parameters": {
        "cma": {
          "event.$": "$",
          "task_config": {
            "provider": "{$.meta.provider}",
            "collection": "{$.meta.collection}",
            "buckets": "{$.meta.buckets}",
            "stack": "{$.meta.stack}"
          }
        }
      },
      "Type": "Task",
      "Resource": "${module.cumulus.discover_granules_task.task_arn}",
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "ResultPath": "$.exception",
          "Next": "WorkflowFailed"
        }
      ],
      "Next": "QueueGranules"
    },
    "QueueGranules": {
      "Parameters": {
        "cma": {
          "event.$": "$",
          "task_config": {
            "provider": "{$.meta.provider}",
            "internalBucket": "{$.meta.buckets.internal.name}",
            "stackName": "{$.meta.stack}",
            "granuleIngestWorkflow": "IngestATL03GranuleWithBrowse",
            "queueUrl": "{$.meta.queues.startSF}"
          }
        }
      },
      "Type": "Task",
      "Resource": "${module.cumulus.queue_granules_task.task_arn}",
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "ResultPath": "$.exception",
          "Next": "WorkflowFailed"
        }
      ],
      "End": true
    },
    "WorkflowFailed": {
      "Type": "Fail",
      "Cause": "Workflow failed"
    }
  }
}
JSON
}

module "ingest_atl03_granule_with_browse_workflow" {
  source = "https://github.com/nasa/cumulus/releases/download/v1.19.0/terraform-aws-cumulus-workflow.zip"

  prefix          = var.prefix
  name            = "IngestATL03GranuleWithBrowse"
  workflow_config = module.cumulus.workflow_config
  system_bucket   = var.system_bucket
  tags            = local.tags

  state_machine_definition = <<JSON
{
  "StartAt": "SyncGranule",
  "States": {
    "SyncGranule": {
      "Parameters": {
        "cma": {
          "event.$": "$",
          "task_config": {
            "buckets": "{$.meta.buckets}",
            "provider": "{$.meta.provider}",
            "collection": "{$.meta.collection}",
            "stack": "{$.meta.stack}",
            "downloadBucket": "{$.cumulus_meta.system_bucket}",
            "duplicateHandling": "{$.meta.collection.duplicateHandling}",
            "pdr": "{$.meta.pdr}",
            "cumulus_message": {
              "input": "{$.payload}",
              "outputs": [
                {
                  "source": "{$.granules}",
                  "destination": "{$.meta.input_granules}"
                },
                {
                  "source": "{$}",
                  "destination": "{$.payload}"
                },
                {
                  "source": "{$.process}",
                  "destination": "{$.meta.process}"
                }
              ]
            }
          }
        }
      },
      "Type": "Task",
      "Resource": "${module.cumulus.sync_granule_task.task_arn}",
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 3
        }
      ],
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "ResultPath": "$.exception",
          "Next": "WorkflowFailed"
        }
      ],
      "Next": "BrowseProcessingStep"
    },
    "BrowseProcessingStep": {
      "Parameters": {
        "cma": {
          "event.$": "$",
          "task_config": {
            "bucket": "{$.meta.buckets.internal.name}",
            "collection": "{$.meta.collection}",
            "cmrMetadataFormat": "{$.meta.cmrMetadataFormat}",
            "additionalUrls": "{$.meta.additionalUrls}",
            "generateFakeBrowse": true,
            "provider": "{$.meta.provider}",
            "cumulus_message": {
              "outputs": [
                {
                  "source": "{$.granules}",
                  "destination": "{$.meta.input_granules}"
                },
                {
                  "source": "{$.files}",
                  "destination": "{$.payload}"
                }
              ]
            }
          }
        }
      },
      "Type": "Task",
      "Resource": "${aws_lambda_function.atl03_extract_browse.arn}",
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "ResultPath": "$.exception",
          "Next": "WorkflowFailed"
        }
      ],
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 1
        }
      ],
      "Next": "FilesToGranulesStep"
    },
    "FilesToGranulesStep": {
      "Parameters": {
        "cma": {
          "event.$": "$",
          "task_config": {
            "inputGranules": "{$.meta.input_granules}",
            "granuleIdExtraction": "{$.meta.collection.granuleIdExtraction}"
          }
        }
      },
      "Type": "Task",
      "Resource": "${module.cumulus.files_to_granules_task.task_arn}",
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "ResultPath": "$.exception",
          "Next": "WorkflowFailed"
        }
      ],
      "Next": "MoveGranuleStep"
    },
    "MoveGranuleStep": {
      "Parameters": {
        "cma": {
          "event.$": "$",
          "task_config": {
            "bucket": "{$.meta.buckets.internal.name}",
            "buckets": "{$.meta.buckets}",
            "distribution_endpoint": "{$.meta.distribution_endpoint}",
            "collection": "{$.meta.collection}",
            "duplicateHandling": "{$.meta.collection.duplicateHandling}"
          }
        }
      },
      "Type": "Task",
      "Resource": "${module.cumulus.move_granules_task.task_arn}",
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "ResultPath": "$.exception",
          "Next": "WorkflowFailed"
        }
      ],
      "End": true
    },
    "WorkflowFailed": {
      "Type": "Fail",
      "Cause": "Workflow failed"
    }
  }
}
JSON
}
