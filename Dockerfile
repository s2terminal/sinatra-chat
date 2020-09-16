FROM ruby:2.7-alpine
WORKDIR /app

RUN apk add --no-cache build-base mysql-dev

COPY Gemfile ./
COPY Gemfile.lock ./
RUN bundle config --local set path 'vendor/bundle'
RUN bundle install

CMD bundle exec ruby index.rb
