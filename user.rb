#encoding=utf-8
class User
  # 用户类
  require 'spec_helper'
  attr_accessor :login_name, :password, :access_token, :network_id, :response_obj

  # 使用指定的登陆名和密码创建一个未登录用户模型
  def initialize options
     @login_name = options[:login_name]
     @password = options[:password]
  end
  
  #  用户登陆
  def login
    response = post '/oauth2/token', params
    self.access_token = response[:access_token]
    log response

    response = get '/api/v1/users/current/home_user', {}, Authorization: "Bearer #{access_token}"
    self.network_id = response[:network_id]
    log response

    response = get '/api/v1/users/current', {}, header
    self.response_obj = response
    log response
    self
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
    self.response_obj[:joined_groups]
  end

  #   向指定工作圈发送消息
  def send_messege group_id, message, options={cc: ""}
    params = {group_id: group_id, body: message, threaded: "extended"}
    post_to_messages params, options
  end

  #   向指定工作圈post一个包含story结构的请求
  def create_story_msg group_id, story, options={cc: ""}
    params = {group_id: group_id, story: story.to_json, threaded: "extended"}
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
    {Authorization: "Bearer #{access_token}", NETWORK_ID: network_id}
  end

  # 返回当前用户的名字
  def name
    response_obj[:name]
  end

  # 创建会话
  def post_to_messages params, options
    params = params.merge options
    response = post "/api/v1/messages", params, header
    log response
    response
  end
end
