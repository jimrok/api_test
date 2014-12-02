#encoding=utf-8

require 'net/http'
require 'json'
require "open-uri"
require 'singleton'

require './helper/spec_helper.rb'
require './user.rb'
require "./helper/business_helper"
require './common/TalkContent.rb'


include SpecHelper
include BusinessHelper

$msgs = []
users = []
offline_users = []
super_admin = nil

class Login
  include Singleton
  attr_accessor :users,:super_admin, :offline_users
end


# TODO:设定登陆方式：邮箱/工号/login_name
ROOT_ADMIN_LOGIN_NAME = 'admin'
ROOT_ADMIN_PWD = 'workasadmin001'

SUPER_ADMIN_LOGIN_NAME = 'admin@ee.com'

def get_login_name user_info
  # user_info[:pinyin] + "ee.com"
  user_info[:login_name]
  # user_info[:emp_code]
end


describe "用户登陆" do
  login = Login.instance

  it "用户名和密码不匹配时应有提示" do
    u = User.new(login_name: "unexist", pwd: "111111").login
    expect(u.errors).to_not be_nil, u.errors.inspect

    u = User.new(login_name: "admin", pwd: "111111").login
    expect(u.errors).to_not be_nil, u.errors.inspect
  end

  it "全网管理员可以登陆" do
    root_admin = User.new(login_name: ROOT_ADMIN_LOGIN_NAME, password: ROOT_ADMIN_PWD).login
#     puts super_admin.inspect
    expect(root_admin.errors).to be_nil, "全网管理员登陆失败，#{super_admin.inspect}"
  end

  it "社区管理员可以登陆并接收推送消息" do
    super_admin = User.new(login_name: SUPER_ADMIN_LOGIN_NAME, password: "111111").login
    login.super_admin = super_admin
#     puts super_admin.inspect
    expect(super_admin.errors).to be_nil, "管理员登陆失败，#{super_admin.errors.inspect}"
    super_admin.receive_mqtt do |topic, msg|
      m = JSON.parse(msg, symbolize_names: true)
      super_admin.messages << m
      $msgs << m
    end
  end
  
  describe do
    it "社区内的用户可以登录并接收推送消息" do
      #let(:users) do
      # 跳过已经登陆的第一个管理员用户，所以实际用户数量是limit - 1
      user_infos = get('/api/v1/users.json', {:page=>1,:limit=>5}, super_admin.header)[:items][1..-1]
      user_infos.each do |user|
        if user != user_infos.last
          user = User.new(login_name: get_login_name(user), password: '111111').login
          expect(user.errors).to be_nil
          user.receive_mqtt do |topic, msg| 
            m = JSON.parse(msg, symbolize_names: true)
            user.messages << m
#             puts "#{user.id}:#{m.inspect}"
            $msgs << m
          end
          expect(user.errors).to be_nil, "登陆失败， #{user.inspect}"
          users << user
        else
         # # 最后一个用户不登陆，备用
          user = User.new(login_name: get_login_name(user), password: '111111')
          offline_users << user
        end
      end
      login.users = users
      login.offline_users = offline_users
      log users.size
    end
  end
 
end
