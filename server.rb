require 'bundler'
Bundler.require

class HelloWorldApp < Sinatra::Base
  set :sprockets, Sprockets::Environment.new(root)
  set :assets_prefix, '/assets'
  set :digest_assets, false

  configure do
    @@clients = []
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


  def setup_websocket ws
    ws.on(:close) { @@clients.delete ws }
    ws.on(:open) { @@clients << ws }

    ws.on :message do |msg|
      puts "THE MESSAGE IS #{msg.data}"
      data = JSON.parse msg.data
      puts "omg data command #{data[:command]}" if data[:command]
      case data['command']
      when 'close'
        MQTT::Client.connect('test.mosquitto.org') do |c|
          puts "OMG CLOSE THIS"
          c.publish('test', 'Close!!!!!')
        end
      when 'open'
        MQTT::Client.connect('test.mosquitto.org') do |c|
          puts "OMG OPEN THIS"
          c.publish('test', 'OPEN!!!!!')
        end
      end
    end
  end

  sub = Thread.new do
    MQTT::Client.connect('mediapc2', 1883) do |c|
      c.get('test') do |topic, message|
        puts "#{topic}: #{message}"
        @@mutex.synchronize do
          @@messages << message
        end
      end
    end
  end


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
    "closed"
  end

  get '/open' do
    data = { command: 'open' }
    @@clients.each { |c| c.send data.to_json }
    "open"
  end

  get '/door/state' do
    @title = 'Upload Video'
    haml :state
  end

end
