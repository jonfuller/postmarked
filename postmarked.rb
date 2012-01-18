require 'sinatra/base'
require 'json'
require 'mongo'

class PostmarkedApp < Sinatra::Base
  before do
    content_type 'application/json'
  end

  get '/raw' do
    #TODO
    200
  end

  post '/push' do
    conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
    uri = URI.parse(ENV['MONGOHQ_URL'])
    db = conn.db(uri.path.gsub(/^\//, ''))
    
    raw = request.env["rack.input"].read
    parsed = JSON.parse(raw)

    app_key = parsed['MailboxHash']
    sender = parsed['From']

    db['postmarked'].insert({:app_key => app_key, :sender => sender, :email => raw})
  end

  post '/pop' do
    #TODO
    200
  end

  post '/apps' do
    #TODO
    '{}'
  end

  delete '/apps/:id' do |id|
    #TODO
    '{}'
  end
end
