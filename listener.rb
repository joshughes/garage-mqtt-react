#!/usr/bin/env ruby
require 'rubygems'
require 'mqtt'

# client = MQTT::Client.connect('mediapc2', 1883)
# topic = 'test'
# # Publish example
#
# client.publish('test', 'message')
#
# # Subscribe example
# client.subscribe(topic)
#
# client.get do |message_topic, message|
#   puts "OMG message topic #{message_topic}"
#   puts "OMG the message #{message}"
# end



# Subscribe example
sub = Thread.new do
  MQTT::Client.connect('mediapc2', 1883) do |c|
    c.get('test') do |topic,message|
      puts "#{topic}: #{message}"
    end
  end
end

puts 'sleep'
sleep 5
puts 'done sleep'
# Publish example
MQTT::Client.connect('mediapc2', 1883) do |c|
  c.publish('test', 'message')
end

sub.join
