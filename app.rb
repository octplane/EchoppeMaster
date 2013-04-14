

get '/em.css' do
  #  headers 'Content-Type' => 'text/css; charset=utf-8'
  scss 'sass/em'.to_sym
end

get '/' do
  @title = "Create a list"
  erb :index
end

post '/create' do

  
end


