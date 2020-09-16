require 'sinatra'
require 'sinatra/reloader' if settings.development?

configure do
  set :bind, '0.0.0.0'
end

get '/' do
  @@chats ||= []
  erb :index, locals: {
    chats: @@chats.map{ |chat| add_suffix(chat) }.reverse
  }
end

post '/' do
  @@chats ||= []
  @@chats.push({ content: params['content'], time: Time.now } )
  redirect back
end

def add_suffix(chat)
  { **chat, content: "#{chat[:content]}も" }
end
