#
# Purpose:
#   ease the bootstraping and hide some terraform magic
#

cloudsql_credential_filename = serlo-production-cloudsql-af533b83d3c3.json
export env_name = production
export gcloud_env_name = serlo_production
export mysql_instance=10072019-1
export postgres_instance=10072019-1

include mk/gcloud.mk
include mk/terraform.mk
