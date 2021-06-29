locals {
  cma_zip_url  = "https://github.com/nasa/cumulus-message-adapter/releases/download/v${var.cumulus_message_adapter_version}/cumulus-message-adapter.zip"
  cma_zip_name = "cumulus-message-adapter-${var.cumulus_message_adapter_version}.zip"
  cma_zip_path = "${path.module}/${local.cma_zip_name}"
}

resource "null_resource" "fetch_CMA_release" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "test ! -f ${local.cma_zip_path} && curl -sL -o ${local.cma_zip_path} ${local.cma_zip_url}"
  }
}

resource "aws_s3_bucket_object" "cma_release" {
  depends_on = [aws_s3_bucket.var_buckets, null_resource.fetch_CMA_release]
  bucket     = var.system_bucket
  key        = local.cma_zip_name
  source     = local.cma_zip_path
}

resource "aws_lambda_layer_version" "cma_layer" {
  s3_bucket   = var.system_bucket
  s3_key      = aws_s3_bucket_object.cma_release.key
  layer_name  = "${var.prefix}-CMA-layer"
  description = "Lambda layer for Cumulus Message Adapter ${var.cumulus_message_adapter_version}"
}
