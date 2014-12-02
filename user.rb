#encoding=utf-8
class User
  # 用户类
  require './helper/spec_helper'
  require './helper/mqtt_helper'
  require 'digest'

  include MqttHelper
  include SpecHelper
  attr_accessor :login_name, :password, :access_token, :network_id, :response_obj, :account_id, :account_channel, :messages

  # 使用指定的登陆名和密码创建一个未登录用户模型
  def initialize options
     @login_name = options[:login_name]
     @password = options[:password]
     @response_obj = nil
  end
  
  #  用户登陆
  def login options={}
    response = post '/oauth2/token', params
    self.access_token = response[:access_token]
    self.network_id = response[:default_network_id]
    log header
    
    response = get '/api/v1/users/current/networks', {}, header
    
    self.account_id = response[:account_id]
    self.account_channel = response[:account_channel]
    self.response_obj = response
    log self.response_obj

    begin
      self.regist_device options
    rescue
      # do nothing.
    end
    
    log response
    self
  end

  def send_pic_to_conversation pic_path, conversation_id
    url = "http://#{HOSTNAME}:#{PORT}/api/v1/uploaded_files"
    pic_path = File.expand_path  pic_path
    pic = File.new pic_path, "rb"

    response_str = RestClient.post(url, {'uploading[]'=> [{data: pic}]}, self.header)
    response = JSON.parse response_str, symbolize_names: true
#     puts response.inspect
    pic_id = response.first[:id]

    response = post "/api/v1/conversations/#{conversation_id}/messages", {'attached[]'=> "uploaded_file:#{pic_id}"}, self.header
    response
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

  def regist_device options={}
    # 默认在登陆时作为安卓设备登陆。可以修改为苹果。
    # iPhone device
    # default_options = {
    #   device_uuid: uuid, device_name: 'iPhone 5s',
    #   apn_token:'',
    #   device_os_version:'8.0', 
    #   client_version: '9.9.9.9',
    # }

    default_options = {
      device_uuid: "10000#{id}", device_name: 'ruby_test_devices',
      apn_token: '766593005693248778', device_sn: '076b62c5',
      device_os_version: '4.3',
      device_fingerprint: 'ruby/ruby/ruby:4.3/JSS15J/N9008VZMUBNA2:user/release-keys'
    }

    params = default_options.merge options
    path = "/api/v1/users/current/devices.json"

    response = post path, params, header
    response
  end

  # 直接根据user_ids发送群聊
  def direct_send_minxin ids, message, options={}
    id_array_str = 
      if ids.is_a? Array
        ids.join ","
      else
        ids.to_s
      end
    
    params = {direct_to_user_ids: id_array_str, body: message}
    post_to_messages params, options, "/api/v1/conversations"
  end

  # 根据会话id发送群聊
  def send_minxin_by_conversation_id conversation_id, message, options={}
    params = {body: message}
    post_to_messages params, options, "/api/v1/conversations/#{conversation_id}/messages"
  end
  
  def send_unLike unlike
    delete '/api/v1/messages/liked_by/current',unlike,header
  end
  
  def send_like like
    post '/api/v1/messages/liked_by/current', like,header
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
    @params ||= { login_name: self.login_name, password: self.password,
             grant_type: GRANT_TYPE, app_id: APP_ID, app_secret: APP_SECRET }
  end

  # 返回当前用户所需要发送的HTTP header
  def header
    @header ||= {Authorization: "bearer #{access_token}", NETWORK_ID: self.network_id}
  end

  # 返回当前用户的名字
  def name
    response_obj[:users].first[:name]
  end

  def messages
    @messages ||= []
  end

  def messagses_to_s
    puts "#{self.id},#{self.name}:#{@messages.inspect}"
  end

  # 创建会话
  def post_to_messages params, options, url="/api/v1/messages"
    params = params.merge options
    response = post url, params, header
    log response
    response
  end
  
  def complete_task tid,id
    post "/api/v1/mini_tasks/#{tid}",{check_item_id:id,checked:true,method:"mark_check_item"},header
  end

  def from_last_seen force_reload=false
    get "/api/v1/conversations/from_last_seen", {force_reload: force_reload}, self.header
  end
  
  def join_activity tid,status
    post "/api/v1/mmodules/event/#{tid}",{proc_name:"merge",status:status},header
  end
  
  def vote tid,id
    post "/api/v1/mmodules/poll/#{tid}",{index:id},header
  end

  def receive_mqtt &p
    mqtt_options = MQTT_OPTIONS.merge client_id: self.response_obj[:account_id].to_s
    t = Thread.new { subscribe response_obj[:account_channel], mqtt_options, &p }
    t.run
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
