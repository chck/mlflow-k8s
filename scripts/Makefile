.PHONY: all
all: help

.PHONY: access  ## Access the server via Cloud IAP Authentification
access:
	$(eval CLIENT_ID := $(shell jq .web.client_id ../infra/secrets/oauth_client_secret.json))
	$(eval SERVICE_ACCOUNT_EMAIL := $(shell jq .client_email $(GOOGLE_APPLICATION_CREDENTIALS)))
	$(eval ID_TOKEN := $(shell gcloud auth print-identity-token \
	    --audiences $(CLIENT_ID) \
	    --impersonate-service-account $(SERVICE_ACCOUNT_EMAIL) \
	    --include-email))
	curl -s -w"\n" -H "Authorization: Bearer $(ID_TOKEN)" $(MLFLOW_TRACKING_URI) -vvv

.PHONY: help ## View help
help:
	@grep -E '^.PHONY: [a-zA-Z_-]+.*?## .*$$' $(MAKEFILE_LIST) | sed 's/^.PHONY: //g' | awk 'BEGIN {FS = "## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
