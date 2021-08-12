# mlflow-k8s
An easy-to-use MLflow platform to track experiments, flexible more users.

Blogged (Japanese): https://cyberagent.ai/blog/research/15272/

![mlflow-k8s](https://user-images.githubusercontent.com/7288735/118874148-87e82a80-b925-11eb-8728-08fd18231900.png)

## Prerequisites
| Software                   | Install (Mac)              |
|----------------------------|----------------------------|
| [Python 3.8.10][python]    | `pyenv install 3.8.10`     |
| [Poetry 1.1.*][poetry]     | `curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py \| python`|
| [direnv][direnv]           | `brew install direnv`      |
| [jq][jq]                   | `brew install jq`          |
| [Docker][docker]           | `brew cask install docker` |
| [Google Cloud SDK][gcloud] | https://cloud.google.com/sdk/docs/quickstart-macos/ |
| [Terraform][terraform]     | `brew tap hashicorp/tap && brew install hashicorp/tap/terraform` |

[python]: https://www.python.org/downloads/release/python-3810/
[poetry]: https://python-poetry.org/
[direnv]: https://direnv.net/
[jq]: https://stedolan.github.io/jq/
[docker]: https://docs.docker.com/docker-for-mac/
[gcloud]: https://cloud.google.com/sdk/
[terraform]: https://learn.hashicorp.com/tutorials/terraform/install-cli/

## Get Started
1. Declare the environment variables
```bash
cp .env.example .env
```

```bash
vi .env
=====================
GCP_PROJECT=YOUR_GCP_PROJECT
GOOGLE_APPLICATION_CREDENTIALS=/path/to/gcp-terraform-credentials.json
TF_GCS_BUCKET=YOUR_PREFIX-tfstate
MLFLOW_GCS_BUCKET=YOUR_PREFIX-mlflow-k8s
MLFLOW_DOMAIN=YOUR_MLFLOW_DOMAIN
MLFLOW_TRACKING_URI=https://${MLFLOW_DOMAIN}/user1/
SERVICE_ACCOUNT_EMAIL=mlflow-k8s@${GCP_PROJECT}.iam.gserviceaccount.com
```

```bash
direnv allow .
```

2. Replace the variables in .tf file for you
```bash
make tf
```

3. Initialize the bucket for terraform
```bash
make bucket
```

4. Run terraform
```bash
cd infra
```

```bash
terraform init
```

```bash
terraform apply
```

5. Check your launched server accessible via Cloud IAP
```bash
cd ..
```

```bash
make access
```
