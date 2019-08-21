ifndef env_name
$(error variable env_name not set)
endif

ifndef cloudsql_credential_filename
$(error variable cloudsql_credential_filename not set)
endif

ifndef gcloud_env_name
$(error variable env_name not set)
endif

kubectl_use_context:
	kubectl config use-context gke_serlo-$(env_name)_europe-west3-a_serlo-$(env_name)-cluster

run_mysql_cloud_sql_proxy:
	cloud_sql_proxy -instances=serlo-$(env_name):europe-west3:serlo-$(env_name)-mysql-instance-$(mysql_instance)=tcp:3306 -credential_file=secrets/$(cloudsql_credential_filename) 

run_postgres_cloud_sql_proxy:
	cloud_sql_proxy -instances=serlo-$(env_name):europe-west3:serlo-$(env_name)-postgres-instance-$(postgres_instance)=tcp:5432 -credential_file=secrets/$(cloudsql_credential_filename) 

