FROM ruby:2.5.3

ENV BUNDLE_PATH=/bundle \
    BUNDLE_BIN=/bundle/bin \
    GEM_HOME=/bundle
ENV PATH="${BUNDLE_BIN}:${PATH}"

RUN mkdir -p /app
WORKDIR /app
COPY . ./
