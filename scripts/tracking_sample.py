import os
from google.auth.transport.requests import Request
from google.oauth2 import id_token
from random import random, randint
import mlflow


def authorize_mlflow() -> None:
    """Create token to access mlflow-k8s via OAuth Identification
    NOTE: 
    The expiration is 1 hour so that you MUST re-create access token regularly.
    Strongly recommend calling this method just before write logs to mlflow.
    """
    # google.oauth2 confirm valid service account w.r.t. GOOGLE_APPLICATION_CREDENTIALS
    assert os.environ["GOOGLE_APPLICATION_CREDENTIALS"] is not None
    os.environ["MLFLOW_TRACKING_TOKEN"] = id_token.fetch_id_token(
        Request(), os.environ["MLFLOW_CLIENT_ID"])
    assert os.environ["MLFLOW_TRACKING_TOKEN"] is not None

authorize_mlflow()
mlflow.set_tracking_uri(os.environ["MLFLOW_TRACKING_URI"])
mlflow.set_experiment("sample")
with mlflow.start_run():
    # Log a parameter (key-value pair)
    mlflow.log_param("param1", randint(0, 100))

    # Log a metric; metrics can be updated throughout the run
    mlflow.log_metric("foo", random())
    mlflow.log_metric("foo", random() + 1)
    mlflow.log_metric("foo", random() + 2)

    # Log an artifact (output file)
    if not os.path.exists("/tmp/outputs"):
        os.makedirs("/tmp/outputs")
    with open("/tmp/outputs/test.txt", "w") as f:
        f.write("hello world!")
    mlflow.log_artifacts("/tmp/outputs")
