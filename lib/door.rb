class Door
  def initialize(pin, sensor, mqtt_client, clients)
    @pin = pin
    @sensor = sensor
    @mqtt_client = mqtt_client
    @clients = clients
  end

  def toggle
    @pin.digital_write(:LOW)
    sleep 2
    @pin.digital_write(:HIGH)
  end

  def closed?
    @sensor.digital_read == :HIGH
  end

  def send_state(state)
    if state
      message = 'OFF'
      data = { command: 'closed' }
      @clients.each { |c| c.send data.to_json }
    else
      data = { command: 'open' }
      @clients.each { |c| c.send data.to_json }
      message = 'ON'
    end
    @mqtt_client.publish('home/garage', message, true, 1)
  end

  def wait_for_state(state)
    Thread.new do
      sleep 30
      send_state(closed?) if closed? != state
    end
  end

  def closed_state(state)
    send_state(state)
    toggle if closed? != state
    wait_for_state(state)
  end
end
