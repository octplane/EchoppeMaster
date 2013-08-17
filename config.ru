path = File.expand_path("../", __FILE__)

require 'rubygems'
require 'sinatra'
require 'sinatra-websocket'
require 'sass'
require 'compass'

path = File.expand_path("../", __FILE__)

set :server, 'thin'
set :environment, :development 
set :sockets, []

set :public_folder, File.join(path, "public")

require "#{path}/app"



run Sinatra::Application
