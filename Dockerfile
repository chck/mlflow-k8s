FROM python:3.8-slim

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
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
 && git clone -b 1.17.0-patch1 --single-branch https://github.com/chck/mlflow.git \
 && cd mlflow/mlflow/server/js \
 && npm install \
 && npm run build
WORKDIR ${APP_DIR}
RUN python setup.py bdist_wheel \
 && pip install -e .

EXPOSE 5000

ENTRYPOINT ["mlflow", "server", "--host=0.0.0.0", "--gunicorn-opts='--worker-class=gevent'"]
CMD ["--workers=1"]
