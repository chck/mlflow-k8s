FROM python:3.9-slim

ENV APP_DIR=${APP_DIR:-"/home/mlflow"}
ENV PYTHONUNBUFFERED=1

RUN apt update && apt install -y --no-install-recommends \
    git \
    nodejs \
    npm \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir poetry==1.1.* \
 && poetry config virtualenvs.create false
COPY pyproject.toml poetry.lock /tmp/
WORKDIR /tmp
RUN poetry install --no-dev

WORKDIR /home
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - \
 && git clone -b v1.28.0 --single-branch https://github.com/mlflow/mlflow.git \
 && cd mlflow/mlflow/server/js \
 && npm install -g -s --no-progress yarn \
 && yarn install \
 && yarn build \
 && yarn cache clean
WORKDIR ${APP_DIR}
RUN python setup.py bdist_wheel \
 && pip install -e .

EXPOSE 5000

ENTRYPOINT ["mlflow", "server", "--host=0.0.0.0", "--gunicorn-opts='--worker-class=gevent'"]
CMD ["--workers=1"]
