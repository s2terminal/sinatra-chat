require 'sinatra'
require 'sinatra/reloader' if settings.development?
require 'sinatra/cookies'
require 'mysql2'

configure do
  set :bind, '0.0.0.0'
end

get '/' do
  name = session_fetch(cookies[:session_id])&.[]("name")
  chats = chats_fetch
  erb :index, locals: {
    name: name,
    chats: chats.map{ |chat| add_suffix(chat) }
  }
end

post '/' do
  name = session_fetch(cookies[:session_id])&.[]("name")
  chat_push(params['content'], name)
  redirect back
end

post '/login' do
  if user = user_fetch(params['name'], params['pass'])
    cookies[:session_id] = SecureRandom.uuid if cookies[:session_id].nil? || cookies[:session_id] == ""
    session_save(cookies[:session_id], { name: user[:name] })
  end
  redirect back
end

get '/logout' do
  cookies[:session_id] = nil
  redirect back
end

get '/initialize' do
  client = Mysql2::Client.new(
    :host => ENV['MYSQL_HOST'],
    :username => ENV['MYSQL_USER'],
    :password => ENV['MYSQL_PASS']
  )
  client.query("DROP DATABASE IF EXISTS #{ENV['MYSQL_DATABASE']}")
  client.query("CREATE DATABASE IF NOT EXISTS #{ENV['MYSQL_DATABASE']}")
  client = db_client
  client.query(<<-EOS
      CREATE TABLE IF NOT EXISTS chats (
        id   INT AUTO_INCREMENT,
        name TEXT,
        content TEXT,
        time DATETIME,
        PRIMARY KEY(id)
    )
    EOS
  )
  client.query(<<-EOS
    CREATE TABLE IF NOT EXISTS users (
      id   INT AUTO_INCREMENT,
      name VARCHAR(255) UNIQUE,
      password TEXT,
      PRIMARY KEY(id),
      INDEX key_index (name)
    );
    EOS
  )
  client.query(<<-EOS
    CREATE TABLE IF NOT EXISTS sessions (
      id   INT AUTO_INCREMENT,
      session_id VARCHAR(255) UNIQUE,
      value_json JSON,
      PRIMARY KEY(id),
      INDEX key_index (session_id)
    );
    EOS
  )
  user_push('admin', 'admin')

  redirect '/'
end

def add_suffix(chat)
  { **chat, content: "#{chat[:content]}も" }
end

def db_client()
  Mysql2::Client.default_query_options.merge!(:symbolize_keys => true)
  Mysql2::Client.new(
    :host => ENV['MYSQL_HOST'],
    :username => ENV['MYSQL_USER'],
    :password => ENV['MYSQL_PASS'],
    :database => ENV['MYSQL_DATABASE']
  )
end

def chat_push(content, name="名無し")
  db_client.prepare(
    "INSERT into chats (name, content, time) VALUES (?, ?, NOW())"
  ).execute(name, content)
end

def chats_fetch()
  db_client.query("SELECT * FROM chats ORDER BY time DESC")
end

def user_push(name, pass)
  db_client.prepare(
    "INSERT into users (name, password) VALUES (?, ?)"
  ).execute(name, pass)
end

def user_fetch(name, pass)
  result = db_client.prepare("SELECT * FROM users WHERE name = ?").execute(name).first
  return unless result
  result[:password] == pass ? result : nil
end

def session_save(session_id, obj)
  db_client.prepare(
    "INSERT into sessions (session_id, value_json) VALUES (?, ?)"
  ).execute(session_id, JSON.dump(obj))
end

def session_fetch(session_id)
  return if session_id == ""
  result = db_client.prepare("SELECT * FROM sessions WHERE session_id = ?").execute(session_id).first
  return unless result
  JSON.parse(result&.[](:value_json))
end
