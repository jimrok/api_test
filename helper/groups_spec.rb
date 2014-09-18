#encoding=utf-8
require 'net/http'
require 'json'
require "open-uri"

require 'spec_helper.rb'
require './user.rb'
require "business_helper"


include SpecHelper
include BusinessHelper

describe "用户" do
  describe "全网管理员" do
    it "应能登陆" do
      login_name = SUPER_ADMIN[:login_name]
      password = SUPER_ADMIN[:password]

      params = {login_name: login_name, password: password, grant_type: GRANT_TYPE, app_id: APP_ID, app_secret: APP_SECRET}
      response = post '/oauth2/token', params
      access_token = response[:access_token]
      expect(access_token).to_not be_nil, "access_token获取错误: #{response}"

      response = get '/api/v1/users/current/home_user', {}, Authorization: "Bearer #{access_token}"
      network_id = response[:network_id]
      expect(network_id).to_not be_nil, "network_id获取错误"

      response = get '/api/v1/users/current', {}, Authorization: "Bearer #{access_token}", network_id: network_id
      expect(response[:errors]).to be_nil, "#{response[:errors]}"
    end

    #   let(:super_admin) {User.new(SUPER_ADMIN).login}
    #   let!(:new_network) { post "/api/v1/networks", RANDOM_NETWORK, super_admin.header}

    super_admin = User.new(SUPER_ADMIN).login
    new_network =  post "/api/v1/networks", RANDOM_NETWORK, super_admin.header
    it "可以创建社区" do
      expect(new_network[:errors]).to be_nil, "创建社区出错#{new_network}"
      log "new_network : #{new_network}", 2
      sleep 3
    end

    it "新社区有默认的社区管理员" do
      user = User.new(login_name: "admin@#{new_network[:web_url].gsub!(/\//, "")}", password: "111111").login
      $dept_admin = user
      $network_id = new_network[:id]
      expect(user.response_obj[:errors]).to be_nil, "登陆失败,#{user.response_obj[:errors]}"
    end
  end

  describe "社区管理员" do
    it "可创建部门" do
      log "user:#{$dept_admin}", 0

      params = {network_id: $network_id }.merge RANDOM_DEPT

      response = post "/api/v1/departments", params, $dept_admin.header
      log "新部门：#{response}", 2
      expect(response[:errors]).to be_nil
    end

    it "可创建用户" do
      $user1_params = {network_id: $network_id }.merge RANDOM_USER_1
      $user2_params = {network_id: $network_id }.merge RANDOM_USER_2

      user1 = post "/api/v1/users", $user1_params, $dept_admin.header
      user2 = post "/api/v1/users", $user2_params, $dept_admin.header

      log "user_1_params is : #{$user1_params}", 2
      log "user_2_params is : #{$user2_params}", 2

      expect(user1[:error]).to be_nil, "user1创建失败：#{user1}"
      expect(user2[:error]).to be_nil, "user2创建失败：#{user2}"

#       laowang = {network_id: $network_id }.merge USER
#       laoli = {network_id: $network_id }.merge USER2

#       user1 = post "/api/v1/users", laowang , $dept_admin.header
#       user2 = post "/api/v1/users", laoli , $dept_admin.header

    end
  end

  describe "普通用户" do
    it "可以使用email登陆" do
      login_name = $user1_params[:email]
      password = $user1_params[:password]

      params = {login_name: login_name, password: password, grant_type: GRANT_TYPE, app_id: APP_ID, app_secret: APP_SECRET}
      response = post '/oauth2/token', params
      access_token = response[:access_token]
      expect(access_token).to_not be_nil, "access_token获取错误: #{response}"

      response = get '/api/v1/users/current/home_user', {}, Authorization: "Bearer #{access_token}"
      network_id = response[:network_id]
      expect(network_id).to_not be_nil, "network_id获取错误"

      response = get '/api/v1/users/current', {}, Authorization: "Bearer #{access_token}", network_id: network_id
      expect(response[:errors]).to be_nil, "#{response[:errors]}"
    end

    it "可以创建工作圈并删除"

    it "可以创建外部社区" # API可以，有时在客户端上会隐藏

    it "不可创建部门"

    it "不可创建用户"
  end
end

describe "群聊" do

  let(:user) {User.new(USER).login}
  let(:admin_user) {User.new(ADMIN_USER_BB).login}

  it "有两个用户登陆了系统" do 
    expect(user.response_obj[:errors]).to be_nil, "普通用户登陆失败：#{user.response_obj[:errors]}"
    expect(admin_user.response_obj[:errors]).to be_nil, "管理员用户登陆失败：#{admin_user.response_obj[:errors]}"
    log "登陆成功"
  end

  it "可以发送消息"

  it "可以屏蔽或解除屏蔽特定聊天的提醒"

  it "可以保存到通讯录或取消保存"

  it "可以改名"

end

describe "社区" do
  it "可以拥有多个工作圈"

  it "若B申请加入外部社区，则管理员A收到审批通知"
end

describe "工作圈" do
  it "不登陆无法发送消息" do
    params = {group_id: 7, body: "消息发送应该不成功", threaded: "extended"}
    response = post "/api/v1/messages", params
    expect(response[:errors]).to_not be_nil
  end

  it "必须包含名称"

  it "若B申请加入私有工作圈，则管理员A收到审批通知"

  let(:user) {User.new(login_name: $user1_params[:email], password: $user1_params[:password]).login}
  let(:admin_user) {User.new(login_name: $dept_admin.login_name, password: "111111").login}

  #   如果有需要可以替换成数据库里已有的两个user，方便在浏览器端查看
#   let(:user) {User.new(USER).login}
#   let(:admin_user) {User.new(ADMIN_USER_BB).login}

  it "有两个用户登陆了系统" do 
    expect(user.response_obj[:errors]).to be_nil, "普通用户登陆失败：#{user.response_obj[:errors]}"
    expect(admin_user.response_obj[:errors]).to be_nil, "管理员用户登陆失败：#{admin_user.response_obj[:errors]}"
    log "登陆成功"
  end

  it "用户可向工作圈中发布、回复消息并能查看到" do
    check_send user, admin_user, "消息", 3 do |user, group_id, msg|
      user.send_messege group_id, msg
    end
  end

  it "用户可向工作圈中发布、回复任务并能查看到" do
    check_send user, admin_user, "任务", 3 do |user, group_id, msg|
      stroy = {app_name: "mini_task", properties: { group_id: group_id, title: msg, check_items: [] }}
      user.create_story_msg group_id, stroy, body: msg
    end
  end


  it "用户可向工作圈中发布、回复活动并能查看到" do
    check_send user, admin_user, "活动", 3 do |user, group_id, msg|
      stroy = {app_name: "event", properties: { description: "活动说明", title: msg, location: "某地点",
                                                start: DateTime.now.to_s, end: (DateTime.now + 3).to_s, 
                                                confirm_end_time: (DateTime.now + 1).to_s
                                              } 
              }
      user.create_story_msg group_id, stroy, body: msg
    end
  end


  it "用户可向工作圈中发布、回复投票并能查看到" do
    check_send user, admin_user, "投票", 3 do |user, group_id, msg|
      stroy = {app_name: "poll", properties: { title: msg, end_date: (DateTime.now + 3).to_s, 
                                                options: ["选项1", "选项2"]
                                             }
              }
      user.create_story_msg group_id, stroy, body: msg
    end
  end

#   it "管理员可向工作圈中发布、回复公告并能查看到" do
#     check_send admin_user, user, "投票", 3 do |admin_user, group_id, msg|
#       stroy = {app_name: "announcement", properties: { title: msg, content: msg, stick: 0 } }
#       admin_user.create_story_msg group_id, stroy, body: msg
#     end
#   end

#   it "非管理员用户不可向工作圈中发布公告" do
#     group_id = user.joined_groups.first[:id]
#     stroy = {app_name: "announcement", properties: { title: "不应该发送成功", content: "不应该发送成功", stick: 0 } }
#     response = user.create_story_msg group_id, stroy
#     expect(response[:errors]).to_not be_nil
#   end
end

describe "通知" do
  it "B回复A的帖子，B收到通知"

  it "B在工作圈发消息atA，A收到at通知"

  it "B在工作圈赞A的帖子，A收到赞通知"

  it "任务被分配给用户B时，B收到通知"

  it "子任务的截止日期发生变更时，负责人收到通知"

  it "子任务被某人完成时，给创建人和所有参与人发送通知"

  it "子任务被某人重新启用时，给创建人和所有参与人发送通知"

end

describe "API" do
end
