#!/bin/bash
set -e

cd deploy/cumulus-tf

../../terraform apply -auto-approve -input=false