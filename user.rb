#encoding=utf-8
class User
  # 用户类
  require 'spec_helper'
  require 'mqtt_helper'
  require 'digest'

  include MqttHelper
  attr_accessor :login_name, :password, :access_token, :network_id, :response_obj,:account_id,:account_channel

  # 使用指定的登陆名和密码创建一个未登录用户模型
  def initialize options
     @login_name = options[:login_name]
     @password = options[:password]
     @response_obj = nil
  end
  
  #  用户登陆
  def login
    response = post '/oauth2/token', params
    self.access_token = response[:access_token]
    self.network_id = response[:default_network_id]
    log header
    
    response = get '/api/v1/users/current/networks', {}, header
    
    self.account_id = response[:account_id]
    self.account_channel = response[:account_channel]
    self.response_obj = response
    log self.response_obj

    response = post '/api/v1/users/current/devices',{:apn_token=>'',:client_version=>'9.9.9.9',:device_name=>'iPhone 5s',:device_os_version=>'8.0',:device_uuid=>uuid}, header
    
    log response
    self
  end
  
  
  def uuid
    Digest::MD5.hexdigest(self.login_name.encode('utf-8'))
  end

  #   查看工作圈
  def view_group group_id
    path = "/api/v1/messages/in_group/#{group_id}"
    params = {threaded: "extended", network_id: network_id}
    response = get path, params, header
    log response
    response
  end

  # 已加入的工作圈
  def joined_groups
    self.response_obj[:users][0][:joined_groups]
  end

  #   向指定工作圈发送消息
  def send_messege group_id, message, options={cc: ""}
    params = {"attached[]"=> "()",group_id: group_id, body: message, threaded: "extended"}
    post_to_messages params, options
  end
  
  def send_unLike unlike
    delete '/api/v1/messages/liked_by/current',unlike,header
  end
  
  def send_like like
    response  = post '/api/v1/messages/liked_by/current', like,header
  end
  
  def delete_message thread_id
    delete '/api/v1/messages/'<< thread_id.to_s,{},header
  end

  #   向指定工作圈post一个包含story结构的请求
  def create_story_msg group_id, story, options={cc: ""}
    params = {"attached[]"=> "()",group_id: group_id, story: story.to_json, threaded: "extended"}
    post_to_messages params, options
  end


  #   返回当前用户的登陆参数
  def params
    p = {grant_type: GRANT_TYPE, login_name: self.login_name, password: self.password,
         app_id: APP_ID, app_secret: APP_SECRET}
    p
  end

  # 返回当前用户所需要发送的HTTP header
  def header
    {:Authorization=> "bearer #{access_token}", :NETWORK_ID=> self.network_id}
  end

  # 返回当前用户的名字
  def name
    response_obj[:users].first[:name]
  end

  # 创建会话
  def post_to_messages params, options
    params = params.merge options
    response = post "/api/v1/messages", params, header
    log response
    response
  end
  
  def complete_task tid,id
    response = post "/api/v1/mini_tasks/#{tid}",{check_item_id:id,checked:true,method:"mark_check_item"},header
  end
  
  def join_activity tid,status
     response = post "/api/v1/mmodules/event/#{tid}",{proc_name:"merge",status:status},header
  end
  
  def vote tid,id
    response = post "/api/v1/mmodules/poll/#{tid}",{index:id},header
  end

  def receive_mqtt &p
    mqtt_options = MQTT_OPTIONS.merge client_id: self.response_obj[:account_id].to_s
    subscribe response_obj[:account_channel], mqtt_options, &p
  end

  def errors
    if self.response_obj.has_key?(:error) 
      self.response_obj[:error]
    elsif self.response_obj.has_key?(:errors) 
      self.response_obj[:errors]
    else
      nil
    end
  end


  def method_missing method, *args
    _method = method.to_sym
    if self.response_obj[:users].first.has_key? _method
      self.response_obj[:users].first[_method]
    else
      super
    end
  end
end
