FROM ruby:2.7-slim
WORKDIR /app

RUN apt-get update && apt-get install -y \
  libmariadb-dev \
  build-essential \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY Gemfile ./
COPY Gemfile.lock ./
RUN bundle config --local set path 'vendor/bundle'
RUN bundle install

CMD bundle exec ruby index.rb
