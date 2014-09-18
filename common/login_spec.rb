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
super_admin = nil

class Login
  include Singleton
  attr_accessor :users,:super_admin
end

# TODO:设定登陆方式：邮箱/工号/login_name
SUPER_ADMIN_LOGIN_NAME = 'admin@ee.com'


describe "用户" do
  login = Login.instance

  it "不匹配的用户名和密码应有提示" do
    u = User.new(login_name: "unexist", pwd: "111111").login
    expect(u.errors).to_not be_nil, u.errors.inspect

    u = User.new(login_name: "admin", pwd: "111111").login
    expect(u.errors).to_not be_nil, u.errors.inspect
  end

  it "管理员登陆" do
    super_admin = User.new(login_name: SUPER_ADMIN_LOGIN_NAME, password: "111111").login
    login.super_admin = super_admin
#     puts super_admin.inspect
    expect(super_admin.errors).to be_nil, "管理员登陆失败，#{super_admin.inspect}"
    super_admin.receive_mqtt do |topic, msg|
      $msgs << JSON.parse(msg, symbolize_names: true)
    end
  end
  
  describe do
    it "获取用户列表,并登录" do
      #let(:users) do
      # 跳过已经登陆的第一个管理员用户
      user_infos = get('/api/v1/users.json', {:page=>1,:limit=>5}, super_admin.header)[:items][1..-1]
      user_infos.each do |user|
        user = User.new(login_name: user[:pinyin] + '@ee.com', password: '111111').login
        user.receive_mqtt do |topic, msg| 
          $msgs << JSON.parse(msg, symbolize_names: true)
        end
        users << user
        expect(user.errors).to be_nil, "登陆失败， #{user.inspect}"
      end
      login.users = users
      log users.size
    end
  end
 
end
