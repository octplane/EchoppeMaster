require 'rufus/mnemo'
require 'mongo'
require 'yaml'



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

else
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
  scss 'sass/em'.to_sym
end

get '/' do
  @title = "Create a list"
  erb :index
end

post '/create' do
  slist = @params['slist'].gsub(/\r\n/,"\n")
  items = slist.split(/\n/).map{ |l| l.strip}

  # compute identifier
  me = (Time.now.to_s + items.join('')).hash % 10000000

  while fetch_doc(me) != nil
    me += 1
  end

  document = { '_id' => me, 'created_at' => Time.now, 'items' => items }

  save_doc(document)


  redirect "/v/#{Rufus::Mnemo.to_s(me)}"
end

get '/v/:id' do
  begin
    id = Rufus::Mnemo.from_s(params[:id])
    doc = fetch_doc(id)
    if doc != nil
      @current_url = params[:id]
      @title = "Shopping list #{@current_url}"
      @items = doc['items']

      erb :shop
    else
      redirect "/404"
    end
  rescue Exception=>e
    $stderr.puts e.inspect
    redirect '/500'
  end
end

get '/404' do
  halt 404
end

get '/500' do
  halt 404
end

