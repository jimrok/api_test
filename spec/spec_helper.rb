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

  HOSTNAME = '192.168.100.218'
  PORT = 8018
  TYPE = ''

  GRANT_TYPE = "password"
  APP_ID = 2
  APP_SECRET = '67bc64352a9c041e75d9635ccafee3b0'

  PRINT_LOG = 2


  # 发送post请求。
  # path: 接口url（不要包含域名）
  # params: 哈希或字符串类型的参数列表。
  # header：发送的HTTP header。
  def post path, params={}, header={}
    params = parse_params(params)
    header = stringed_hash header

    response = receive_post_response path, params, header
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
  # path: 接口url（不包含域名）
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


  # 调试时所使用的log方法。当指定的level参数大于spec_helper中的PRINT_LOG时，向控制台输出指定字符串。
  def log str, level=0
    puts "    #{str}" if level > PRINT_LOG
  end

  # 输出带颜色的字符串到终端。默认为红色。
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

  # 向终端输出一个响铃符号。
  def alarm
    print "\a"
  end

  private

  def receive_post_response path, params={}, header={}, count=0
    Net::HTTP.start(HOSTNAME, PORT) do |http|
      begin
        http.request_post("#{path}#{TYPE}",params , header)
        # TODO:判断如果http返回码是502,则稍等尝试重发一次
      rescue Timeout::Error
        # 捕获NGINX超时
        $time_out_count_post += 1
        count += 1
        if count <= 3
          puts "timeout. wait and retry."
          sleep 1
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
        sleep 2
        response = receive_get_response h, url, header, count
      else
        p "重试3次依然超时。"
      end
    end
  end

  # 将哈希表里的key和value都转换成字符串
  def stringed_hash hash
    h = {}
    hash.each { |key, value| h[key.to_s] = value.to_s }
    h
  end

  # 将哈希形式的参数表包装成字符串形式并将参数值进行url编码。如果已经是字符串，则不变。
  def parse_params params
    if params.is_a? String
      params
    else
      p = stringed_hash params

      params_string = p.inject('') { |sum, k| sum += "#{k.first.to_s}=#{URI.encode_www_form_component k.last}&" }[0..-2]
      params_string
    end
  end


  # 未使用
  # 将哈希形式的header包装成字符串形式并将参数值进行url编码。如果已经是字符串，则不变。
  def parse_header header
    if header.is_a? String
      header 
    else
      h = stringed_hash header

      header_string = h.inject('') { |sum, k| sum += "#{k.first.to_s}:#{k.last} " }[0..-2]
      header_string
    end
  end
end
