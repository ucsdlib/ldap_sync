FROM ruby:2.5.3 as builder

WORKDIR /src
COPY Gemfile* ./
RUN bundle install --jobs 4 --retry 2

FROM ruby:2.5.3-slim

RUN mkdir -p /app
WORKDIR /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY . ./

ENTRYPOINT ["./sync.rb"]
