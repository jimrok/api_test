#encoding=utf-8
module SpecHelper
  require 'net/http'
  require 'json'
  require "open-uri"
  require "./seeds.rb"
  require 'rest_client'

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

#   HOSTNAME = '192.168.100.102'
#   PORT = 3000

  HOSTNAME = '192.168.100.230'
  PORT = 8030
  MQTT_PORT = 1830
  TYPE = ''

  MQTT_OPTIONS = {
    remote_host: "192.168.100.230",
    remote_port:  MQTT_PORT,
    username: "server",
    password: "minxing123",
    ssl: true
  }

  GRANT_TYPE = "password"
  APP_ID = 2
  APP_SECRET = '67bc64352a9c041e75d9635ccafee3b0'

  PRINT_LOG = 2


  # 发送post请求。
  # path: 接口url（不要包含域名）
  # params: 哈希或字符串类型的参数列表。
  # header：发送的HTTP header。
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
  
  
  # 发送put请求。
  # path: 接口url（不要包含域名）
  # params: 哈希或字符串类型的参数列表。
  # header：发送的HTTP header。
  def put path, params={}, header={}
    params = parse_params(params)
    header = stringed_hash header

    response = receive_put_response path, params, header
    begin
      response_hash = JSON.parse(response.body, symbolize_names: true)
      log response_hash, 0
    rescue  StandardError
      response_hash = { errors: "not a json!" }
      $errors_count_post += 1
#       log response.body, 100000
    end
    $total_post += 1
    response_hash
  end


  # 发送get请求。
  # path: 接口url（不要包含域名）
  # params: 哈希或字符串类型的参数列表。
  # header：发送的HTTP header。
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
  
  # 发送delete请求。
  # path: 接口url（不要包含域名）
  # params: 哈希或字符串类型的参数列表。
  # header：发送的HTTP header。
  def delete path,params={},header={}
    url = "#{path}#{TYPE}?#{parse_params(params)}"
    header = stringed_hash header
    response = receive_delete_response url, header
    log response
    begin
      ret = response.code
    rescue  StandardError
      ret = "500"
    end
    $total_get += 1
    ret
  end


  # 如果指定的输出等级大于PRINT_LOG，则在控制台中输出字符串
  # 如果指定了color参数则输出带颜色的字符串
  def log str, level=0, color=nil
    str = 
      if color
        colored_str str, color
      else
        str
      end
    puts "    #{str}" if level > PRINT_LOG
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
#             sleep 5
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
#         sleep 5
        receive_post_response path, params, header, count
      else
        p "3次连接被拒绝。退出。"
      end
    rescue Errno::ECONNRESET
      $reset_by_peer += 1
      count += 1
      if count <= 3
        puts "reset_by_peer #{count} times. wait and retry."
#         sleep 5
        receive_post_response path, params, header, count
      else
        p "3次依然被重置。退出。"
      end

    end
  end
  
  def receive_put_response path, params={}, header={}, count=0
    Net::HTTP.start(HOSTNAME, PORT) do |http|
      begin
        http.request_put("#{path}#{TYPE}",params , header)
        # TODO:判断如果http返回码是502,则稍等尝试重发一次
      rescue Timeout::Error
        # 捕获NGINX超时
        $time_out_count_post += 1
        count += 1
        if count <= 3
          puts "timeout. wait and retry."
#           sleep 1
          receive_post_response path, params, header, count
        else
          p "3次超时。退出。"
        end
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
#         sleep 5
        response = h.request_get url, header
      else
        p "重试3次依然超时。"
      end
    rescue Errno::ECONNREFUSED
      $time_out_count_get += 1
      count += 1
      if count <= 3
        puts "timeout. wait and retry."
#         sleep 5
        response = h.request_get url, header
      else
        p "重试3次依然被拒绝。"
      end
    rescue Errno::ECONNRESET
      $reset_by_peer += 1
      count += 1
      if count <= 3
        puts "reset_by_peer. wait and retry."
#         sleep 5
        response = h.request_get url, header
      else
        p "重试3次依然被重置。"
      end
    end
  end
  
  def receive_delete_response url,header, count=0
    h = Net::HTTP.new HOSTNAME, PORT
    begin
      response = h.delete url, header
    rescue Timeout::Error
      $time_out_count_get += 1
      count += 1
      if count <= 3
        puts "timeout. wait and retry."
#         sleep 2
        response = receive_delete_response h, url, header, count
      else
        p "重试3次依然超时。"
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

  # 返回能够被终端识别的、带颜色的字符串。默认为蓝色;若color为'red'或布尔值false，则输出红色。
  def colored_str message, color = 'sky'
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
    when false
      color = '31;1'  
    else
      color = '36;1'  
    end  

    "\e[#{color}m#{message}\e[0m\n"   
  end  
end
