module MqttHelper
  require 'rubygems'
  require 'mqtt'
  
  # Subscribe example
  def subscribe channel, options, &p
    MQTT::Client.connect(options) do |c|
      # If you pass a block to the get method, then it will loop
      c.get(channel) do |topic,message|
        if block_given?
          p.call topic, message
        else
          puts "收到消息#{topic}: #{message}"
        end
      end
    end
  end
end
