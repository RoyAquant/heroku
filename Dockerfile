ARG TF_SERVING_VERSION=latest
ARG TF_SERVING_BUILD_IMAGE=tensorflow/serving:${TF_SERVING_VERSION}-devel

FROM ${TF_SERVING_BUILD_IMAGE} as build_image
FROM ubuntu:18.04

ARG TF_SERVING_VERSION_GIT_BRANCH=master
ARG TF_SERVING_VERSION_GIT_COMMIT=head

LABEL maintainer="gvasudevan@google.com"
LABEL tensorflow_serving_github_branchtag=${TF_SERVING_VERSION_GIT_BRANCH}
LABEL tensorflow_serving_github_commit=${TF_SERVING_VERSION_GIT_COMMIT}

ENV MODEL_NAME=aquantmodel
ENV MODEL_BASE_PATH=/models

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        && \
    apt-get -y install wget && \
    apt-get -y install curl && \
    apt-get -y install net-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build_image /usr/local/bin/tensorflow_model_server /usr/bin/tensorflow_model_server

RUN mkdir -p ${MODEL_BASE_PATH}

RUN wget http://bucketeer-14c8ab4d-3c8f-427a-a64a-a454a807ab62.s3.amazonaws.com/public/${MODEL_NAME}.tar.gz
RUN tar -xzvf ${MODEL_NAME}.tar.gz -C /models

RUN echo '#!/bin/bash \n\n\
tensorflow_model_server --rest_api_port=${PORT} \
--model_name=${MODEL_NAME} --model_base_path=${MODEL_BASE_PATH}/${MODEL_NAME} \
"$@"' > /usr/bin/tf_serving_entrypoint.sh \
&& chmod +x /usr/bin/tf_serving_entrypoint.sh