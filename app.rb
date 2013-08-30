require 'rufus/mnemo'
require 'mongo'
require 'yaml'
require 'json'

if ENV['VCAP_SERVICES']

  def list_db
    @list_db ||= begin
      url = JSON.parse(ENV['VCAP_SERVICES'])['mongodb-1.8'].first["credentials"]["url"]
      cnx = Mongo::Connection.from_uri(url)['paste']
      cnx['pastes']
    end
  end

  def fetch_doc(id)
    list_db.find_one({"_id" => id })
  end

  def save_doc(data)
    list_db.insert(data, :safe => true)
  end

  def cleanup
    list_db.remove({'expire' => { '$lte' => Time.now.to_i}})
  end

  get '/vcap' do
    JSON.parse(ENV['VCAP_SERVICES'])
  end

else
  get '/vcap' do
    "pouet"
  end
  require 'fileutils'
  DATA_FOLDER = File.join(File.dirname(__FILE__), 'data')
  if ! File.exists?(DATA_FOLDER)
    FileUtils.mkdir_p(DATA_FOLDER)
  end

  def fetch_doc(id)
    f = File.join(DATA_FOLDER, "#{id}.yaml")
    if !File.exist?(f)
      return nil
    end
    return YAML::load( File.open( f ) )
  end
  def save_doc(data)
    dest_file = File.join(DATA_FOLDER, "#{data['_id']}.yaml")
    File.open(dest_file, "wb") {|file| file.puts(data.to_yaml) }
  end
  def cleanup
    # NOOP
  end
end


get '/em.css' do
  #  headers 'Content-Type' => 'text/css; charset=utf-8'
  scss 'sass/em'.to_sym,  line_numbers: true # {:style => :compact, :debug_info => false}
end

get '/' do
  @title = "Welcome to Share & Shop !"
  erb :index
end

get '/create' do
  @title = "Create a list"
  erb :create
end

post '/create' do
  slist = @params['slist'].gsub(/\r\n/,"\n")
  email = @params['email']


  items = slist.split(/\n/).map{ |l| l.strip}
  items.reject! { |i| i == ""}

  # compute identifier
  me = (Time.now.to_s + items.join('')).hash % 10000000

  storable_items = {}
  keys = []

  items.each_with_index do |i, ix|
    id = "#{i}#{ix}".hash.to_s(36)
    keys << id
    storable_items[id] = { :checked => false, :name => i, :updated => Time.now}
  end


  # concurency hell.
  while fetch_doc(me) != nil
    me += 1
  end
  document = { '_id' => me, 'email' => email, 'created_at' => Time.now, 'keys' => keys, 'items' => storable_items }
  save_doc(document)


  redirect "/v/#{Rufus::Mnemo.to_s(me)}"
end

get '/v/:id' do

    id = Rufus::Mnemo.from_s(params[:id])
    doc = fetch_doc(id)
    if doc != nil
      if !request.websocket?
        @current_url = params[:id]
        @title = "Shopping list #{@current_url}"
        @items = doc['items']

        erb :shop
      else
   request.websocket do |ws|
      ws.onopen do
        ws.send('c')
        settings.sockets << ws
      end
      ws.onmessage do |msg|
        EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
      end
      ws.onclose do
        warn("wetbsocket closed")
        settings.sockets.delete(ws)
      end

      end
      end
    else
      redirect "/404"
    end
end

get '/api/1/:id' do

    id = Rufus::Mnemo.from_s(params[:id])
    doc = fetch_doc(id)
    if doc != nil
      @current_url = params[:id]
      @title = "Shopping list #{@current_url}"
      @items = doc['items']
      return doc.to_json
    end
end




get '/404' do
  halt 404
end

get '/500' do
  halt 404
end


