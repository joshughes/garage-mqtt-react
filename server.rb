require 'bundler'
Bundler.require
include Beaglebone
require_relative 'lib/door'

class HelloWorldApp < Sinatra::Base
  set :sprockets, Sprockets::Environment.new(root)
  set :assets_prefix, '/assets'
  set :digest_assets, false
  MQTT_CLIENT = MQTT::Client.connect(ENV['MQTT_SERVER'],
                                     port: 1883,
                                     username: ENV['MQTT_USER'],
                                     password: ENV['MQTT_PASSWORD'])

  DOOR_CONTROL_PIN = GPIOPin.new(:P8_7, :OUT)
  DOOR_CONTROL_PIN.digital_write(:HIGH)
  DOOR_SENSOR_PIN = GPIOPin.new(:P8_13, :IN)

  configure do
    @@clients = []
    @@door = Door.new(DOOR_CONTROL_PIN, DOOR_SENSOR_PIN, MQTT_CLIENT, @@clients)

    # Setup Sprockets
    sprockets.append_path File.join(root, 'assets', 'stylesheets')
    sprockets.append_path File.join(root, 'assets', 'javascripts')
    sprockets.append_path File.join(root, 'assets', 'images')

    set :dump_errors, true
    @@messages, @@mutex = [], Mutex.new
    DataMapper::setup(:default, File.join('sqlite3://', Dir.pwd, 'door.db'))
    require_relative 'models/door_event'
    require_relative 'models/door'
    DataMapper.finalize
    DataMapper.auto_upgrade!

    # Configure Sprockets::Helpers (if necessary)
    Sprockets::Helpers.configure do |config|
      config.environment = sprockets
      config.prefix      = assets_prefix
      config.digest      = digest_assets
      config.public_path = public_folder

      # Force to debug mode in development mode
      # Debug mode automatically sets
      # expand = true, digest = false, manifest = false
      config.debug       = true if development?
    end
  end

  helpers do
    include Sprockets::Helpers

    # Alternative method for telling Sprockets::Helpers which
    # Sprockets environment to use.
    # def assets_environment
    #   settings.sprockets
    # end
  end

  def setup_websocket(ws)
    ws.on(:close) do
      @@mutex.synchronize do
        @@clients.delete ws
      end
    end
    ws.on(:open) do
      @@mutex.synchronize do
        @@clients << ws
      end
    end

    ws.on :message do |msg|
      puts "THE MESSAGE IS #{msg.data}"
      data = JSON.parse msg.data
      puts "omg data command #{data[:command]}" if data[:command]
      case data['command']
      when 'close'
        @@door.closed_state(true)
      when 'open'
        @@door.closed_state(false)
      end
    end
  end

  Thread.new do
    MQTT_CLIENT.get('home/garage/set') do |topic, message|
      puts "#{topic}: #{message}"
      @@mutex.synchronize do
        @@messages << message
      end
      puts "THE message '#{message}' does equal ON: #{message == 'ON'}"
      puts "Message type String: #{message.instance_of? String}"
      if message == 'ON'
        @@door.closed_state(false)
      elsif message == 'OFF'
        @@door.closed_state(true)
      end
    end
  end

  callback = Proc.new do |pin,edge,count|
    puts "[#{count}] #{pin} #{edge}"
    sleep 30
    if @@door.closed?
      data = { command: 'closed' }
      @@clients.each { |c| c.send data.to_json }
      @@door.send_state(true)
    else
      data = { command: 'open' }
      @@clients.each { |c| c.send data.to_json }
      @@door.send_state(false)
    end
    puts "Saw a #{edge} edge"
  end

  DOOR_SENSOR_PIN.run_on_edge(callback, :BOTH)

  get '/' do
    if Faye::WebSocket.websocket? request.env
      ws = Faye::WebSocket.new request.env
      setup_websocket ws
      ws.rack_response
    else
      'Hello, world!'
    end
  end

  # get '/:name' do
  #   "Hello, #{params[:name]}!"
  # end

  get '/messages' do
    "Messages: #{@@messages}"
  end

  get '/close' do
    data = { command: 'closed' }
    @@clients.each { |c| c.send data.to_json }
    'closed'
  end

  get '/open' do
    data = { command: 'open' }
    @@clients.each { |c| c.send data.to_json }
    'open'
  end

  get '/door/state' do
    @title = 'Door State'
    haml :state
  end
end
