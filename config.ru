path = File.expand_path("../", __FILE__)

require 'rubygems'
require 'sinatra'
require 'sass'
require 'compass'

path = File.expand_path("../", __FILE__)
set :public_folder, File.join(path, "public")

require "#{path}/app"



run Sinatra::Application
