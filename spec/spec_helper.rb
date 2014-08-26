#encoding=utf-8
module SpecHelper
  require 'net/http'
  require 'json'
  require "open-uri"
  require "./helpers/seeds.rb"

  include Seeds

  # HOSTNAME = 'nagae-memooff.me'
  # PORT = 80
  # TYPE = '.json'

  $total_post = 0
  $total_get = 0
  $errors_count_post = 0
  $errors_count_get = 0
  $time_out_count_post = 0
  $time_out_count_get = 0
  $reset_by_peer = 0

  HOSTNAME = '192.168.100.218'
  PORT = 8018
  MQTT_PORT = 1883
  TYPE = ''

  MQTT_OPTIONS = {
    remote_host: HOSTNAME,
    remote_port:  MQTT_PORT,
    username: "server",
    password: "minxing123",
    ssl: true
  }

  GRANT_TYPE = "password"
  APP_ID = 2
  APP_SECRET = '67bc64352a9c041e75d9635ccafee3b0'

  PRINT_LOG = 2


  def post path, params={}, header={}, count=0
    params = parse_params(params)
    header = stringed_hash header

    response = receive_post_response path, params, header
    begin
      response_hash = JSON.parse(response.body, symbolize_names: true)
      log response_hash, 0
    rescue  StandardError
      $errors_count_post += 1
      log "not a json, retry!", 5
      count += 1
      response_hash = 
        if count > 3
          log "三次尝试失败", 5
          { errors: "not a json!" }
        else
          post path, params, header, count
        end
      #       log response.body, 100000
    end
    $total_post += 1
    response_hash
  end



  def get path, params={}, header={}
    h = Net::HTTP.new HOSTNAME, PORT
    url = "#{path}#{TYPE}?#{parse_params(params)}"
      header = stringed_hash header

    response = receive_get_response h, url, header

    begin
      response_hash = JSON.parse(response.body, symbolize_names: true)
      log response_hash, 0
    rescue  StandardError
      response_hash = { errors: "not a json!" }
      #       log response.body, 1
    end
    $total_get += 1
    response_hash
  end


  def log str, level=0
    puts "    #{str}" if level > PRINT_LOG
  end

  def colored_str(message, color = 'red')  
    case color  
    when 'red'     
      color = '31;1'  
    when 'green'
      color = '32;1'  
    when 'yellow'
      color = '33;1'  
    when 'blue'
      color = '34;1'  
    when 'purple'
      color = '35;1'  
    when 'sky'
      color = '36;1'  
    else
      color = '36;1'  
    end  

    "\e[#{color}m#{message}\e[0m\n"   
  end  

  def alarm
    print "\a"
  end

  private

  def receive_post_response path, params={}, header={}, count=0
    begin
      Net::HTTP.start(HOSTNAME, PORT) do |http|
        begin
          http.request_post("#{path}#{TYPE}",params , header)
          # TODO:判断如果http返回码是502,则稍等尝试重发一次
        rescue Timeout::Error
          $time_out_count_post += 1
          count += 1
          if count <= 3
            puts "timeout #{count} times. wait and retry."
            sleep 5
            receive_post_response path, params, header, count
          else
            p "3次超时。退出。"
          end
        rescue Errno::ECONNREFUSED
          $time_out_count_post += 1
          count += 1
          if count <= 3
            puts "timeout #{count} times. wait and retry."
            sleep 5
            receive_post_response path, params, header, count
          else
            p "3次超时。退出。"
          end
        end
      end
    rescue Errno::ECONNREFUSED
      $time_out_count_post += 1
      count += 1
      if count <= 3
        puts "timeout #{count} times. wait and retry."
        sleep 5
        receive_post_response path, params, header, count
      else
        p "3次超时。退出。"
      end
    rescue Errno::ECONNRESET
      $reset_by_peer += 1
      count += 1
      if count <= 3
        puts "reset_by_peer #{count} times. wait and retry."
        sleep 5
        receive_post_response path, params, header, count
      else
        p "3次超时。退出。"
      end

    end
  end

  def receive_get_response h, url, header, count=0
    begin
      response = h.request_get url, header
    rescue Timeout::Error
      $time_out_count_get += 1
      count += 1
      if count <= 3
        puts "timeout. wait and retry."
        sleep 5
        response = h.request_get url, header
      else
        p "重试3次依然超时。"
      end
    rescue Errno::ECONNREFUSED
      $time_out_count_get += 1
      count += 1
      if count <= 3
        puts "timeout. wait and retry."
        sleep 5
        response = h.request_get url, header
      else
        p "重试3次依然超时。"
      end
    rescue Errno::ECONNRESET
      $reset_by_peer += 1
      count += 1
      if count <= 3
        puts "reset_by_peer. wait and retry."
        sleep 5
        response = h.request_get url, header
      else
        p "重试3次依然被重置。"
      end
    end
  end

  def parse_params params
    if params.is_a? String
      params
    else
      p = stringed_hash params

      params_string = p.inject('') { |sum, k| sum += "#{k.first.to_s}=#{URI.encode_www_form_component k.last}&" }[0..-2]
      params_string
    end
  end


  def parse_header header
    if header.is_a? String
      header 
    else
      h = stringed_hash header

      header_string = h.inject('') { |sum, k| sum += "#{k.first.to_s}:#{k.last} " }[0..-2]
      header_string
    end
  end

  def stringed_hash hash
    h = {}
    hash.each { |key, value| h[key.to_s] = value.to_s }
    h
  end
end
