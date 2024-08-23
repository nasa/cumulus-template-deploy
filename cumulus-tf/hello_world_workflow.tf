module "hello_world_workflow" {
  source = "https://github.com/nasa/cumulus/releases/download/v18.4.0/terraform-aws-cumulus-workflow.zip"

  prefix          = var.prefix
  name            = "HelloWorldWorkflow"
  workflow_config = module.cumulus.workflow_config
  system_bucket   = var.system_bucket
  tags            = local.tags

  state_machine_definition = templatefile(
    "${path.module}/hello_world_workflow.asl.json",
    {
      hello_world_task_arn: module.cumulus.hello_world_task.task_arn
    }
  )
}
