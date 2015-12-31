require 'rubygems'
require 'bundler/setup'
require './server'

Faye::WebSocket.load_adapter('thin')

map HelloWorldApp.assets_prefix do
  run HelloWorldApp.sprockets
end

map "/" do
  run HelloWorldApp
end
