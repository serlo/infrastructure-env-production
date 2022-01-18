# Production-Infrastructure for Serlo

## Introduction

Serlo's infrastructure is based on Terraform, Kubernetes and the Google Cloud Platform.

We currently support the following environments:

1. **https://serlo-development.dev** (development environment for new infrastructure code, deployable by all serlo devs - https://github.com/serlo/infrastructure-env-dev)
1. **https://serlo-staging.dev** (staging environment to test and integrate infrastructure and apps, deployable only by infrastructure unit - https://github.com/serlo/infrastructure-env-staging)
1. **https://serlo.org** (production environment, deployable only by infrastructure unit - https://github.com/serlo/infrastructure-env-production)

To get access to our staging environment please contact us.

## Deployment process for production

The deployment of infrastructure code or new app versions into production has to be reviewed by the infrastructure unit.

Therefore, please open a new **pull request** into main.
