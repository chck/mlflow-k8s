GKE_CLUSTER:=mlflow-k8s
REGION:=asia-northeast1
$(shell gcloud config set project ${GCP_PROJECT})

.PHONY: all
all: help

.PHONY: init  ## Initialize the bucket for terraform
init:
	gsutil mb -c NEARLINE -l $(REGION) gs://$(TF_GCS_BUCKET) || true
	gsutil versioning set on gs://$(TF_GCS_BUCKET)

.PHONY: creds  ## Set kubeconfig via our GKE for development
creds:
	gcloud container clusters get-credentials $(GKE_CLUSTER) --region $(REGION)
	kubectl config use-context gke_$(GCP_PROJECT)_$(REGION)_$(GKE_CLUSTER)
	kubectl config get-contexts

.PHONY: replace  ## Replace the dummy variables to your ones in .tf file
replace:
	sed -i "" s/_YOUR_PROJECT/${GCP_PROJECT}/g infra/*.tf
	sed -i "" s/_YOUR_BUCKET/${TF_GCS_BUCKET}/g infra/*.tf
	sed -i "" s/_YOUR_MLFLOW_DOMAIN/${MLFLOW_DOMAIN}/g infra/*.tf

.PHONY: access  ## Access the server via Cloud IAP Authentification
access:
	$(eval CLIENT_ID := $(shell jq .web.client_id infra/secrets/oauth_client_secret.json))
	$(eval ID_TOKEN := $(shell gcloud auth print-identity-token \
	    --audiences $(CLIENT_ID) \
	    --impersonate-service-account $(SERVICE_ACCOUNT_EMAIL) \
	    --include-email))
	curl -s -w"\n" -H "Authorization: Bearer $(ID_TOKEN)" $(MLFLOW_ENDPOINT) -vvv

.PHONY: help ## View help
help:
	@grep -E '^.PHONY: [a-zA-Z_-]+.*?## .*$$' $(MAKEFILE_LIST) | sed 's/^.PHONY: //g' | awk 'BEGIN {FS = "## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
