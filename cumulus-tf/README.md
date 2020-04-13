Before running `terraform apply`, make sure the browse imagery's `lambda.zip`
file exists (see the root README for instructions on creating this), or run
`terraform apply -target=main.tf` to only target `main.tf`, rather
than all `.tf` files in this directory.
