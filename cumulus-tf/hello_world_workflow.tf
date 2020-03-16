module "hello_world_workflow" {
  source = "https://github.com/nasa/cumulus/releases/download/v1.20.0/terraform-aws-cumulus-workflow.zip"

  prefix                                = var.prefix
  name                                  = "HelloWorldWorkflow"
  workflow_config                       = module.cumulus.workflow_config
  system_bucket                         = var.system_bucket
  tags                                  = local.tags

  state_machine_definition = <<JSON
{
  "Comment": "Returns Hello World",
  "StartAt": "HelloWorld",
  "States": {
    "HelloWorld": {
      "Parameters": {
        "cma": {
          "event.$": "$",
          "task_config": {
            "buckets": "{$.meta.buckets}",
            "provider": "{$.meta.provider}",
            "collection": "{$.meta.collection}"
          }
        }
      },
      "Type": "Task",
      "Resource": "${module.cumulus.hello_world_task.task_arn}",
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
      "End": true
    }
  }
}
JSON
}
