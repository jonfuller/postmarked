require 'sinatra/base'
require 'json'
require 'mongo'
require 'securerandom'
require 'digest/sha1'

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

    return 404 unless db['apps'].find_one({'app_key' => app_key})

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
    conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
    uri = URI.parse(ENV['MONGOHQ_URL'])
    db = conn.db(uri.path.gsub(/^\//, ''))

    return 400 unless params.has_key? 'app_name'

    app_name = params['app_name']
    app_key = generate_key
    while db['apps'].find_one({'app_key' => app_key})
      app_key = generate_key
    end

    doc = {'app_key' => app_key, 'app_name' => app_name}

    db['apps'].insert(doc)

    doc.reject{|k,v| k.to_s == '_id'}.to_json
  end

  delete '/apps/:key' do |app_key|
    conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
    uri = URI.parse(ENV['MONGOHQ_URL'])
    db = conn.db(uri.path.gsub(/^\//, ''))

    return 404 unless removed = db['apps'].find_and_modify({
      :remove => true,
      :query => {'app_key' => app_key}})
    
    removed.reject{|k,v| k.to_s == '_id'}.to_json
  end

  def generate_key
    Digest::SHA1.hexdigest(Time.now.to_s+SecureRandom.random_number.to_s)
  end
end
