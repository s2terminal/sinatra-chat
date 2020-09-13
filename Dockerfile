FROM ruby:2.7-alpine
WORKDIR /app

COPY Gemfile ./
COPY Gemfile.lock ./
RUN bundle config set path 'vendor/bundle'
RUN bundle install

CMD bundle exec ruby index.rb
