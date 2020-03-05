# Cumulus Deployment Project
## How To Deploy
Documentation for how to use the Cumulus template project can be read online:

[https://nasa.github.io/cumulus/docs/deployment/deployment-readme](https://nasa.github.io/cumulus/docs/deployment/deployment-readme)

### Additional Deployment notes

* more notes and details are available at
  https://wiki.earthdata.nasa.gov/display/NDCUM/Ordered+steps+for+gaining+access+to+NGAP+NSIDC+Sandbox#app-switcher
* for sandbox, the JWT secrets are named `nsidc-sb_jwt_secret_for_tea`; see the
  [AWS Secrets
  page](https://us-west-2.console.aws.amazon.com/secretsmanager/home?region=us-west-2#/listSecrets)
* Several `.example` files use a prefix of `nsidc-sb`; update that to a prefix
  appropriate for your deployment environment (e.g., `nsidc-sit`)
