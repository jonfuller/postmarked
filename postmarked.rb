require 'sinatra/base'
require 'json'
require 'mongo'

class PostmarkedApp < Sinatra::Base
  before do
    content_type 'application/json'
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
    conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
    uri = URI.parse(ENV['MONGOHQ_URL'])
    db = conn.db(uri.path.gsub(/^\//, ''))

    return 400 unless params.has_key? 'app_key'

    doc = db['postmarked'].find_and_modify({
      :remove => true,
      :query => {'app_key' => params[:app_key]}})

    return 404 unless doc

    doc['email']
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
