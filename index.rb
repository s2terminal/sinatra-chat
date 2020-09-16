require 'sinatra'
require 'sinatra/reloader' if settings.development?

configure do
  set :bind, '0.0.0.0'
end

get '/' do
  'Hello Sinatra!'
end
