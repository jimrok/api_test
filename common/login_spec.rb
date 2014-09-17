#encoding=utf-8

require 'net/http'
require 'json'
require "open-uri"

require './spec/spec_helper.rb'
require './user.rb'
require "./spec/business_helper"
require './common/TalkContent.rb'


include SpecHelper
include BusinessHelper

users = []
super_admin = nil

class Login
  attr_accessor :users,:super_admin
  @@instance = Login.new
  def self.getInstance
    @@instance
  end
end

# TODO:设定登陆方式：邮箱/工号/login_name



describe "用户" do
  login = Login.getInstance
  it "管理员登陆" do
    super_admin = User.new({:login_name=>'admin@ee.com',:password=>'111111'}).login
    login.super_admin = super_admin
#     puts super_admin.inspect
    expect(super_admin.errors).to be_nil, "管理员登陆失败，#{super_admin.inspect}"
    
  end
  
  describe do
    it "获取用户列表,并登录" do
    #let(:users) do
      user_infos = get('/api/v1/users.json', {:page=>1,:limit=>4}, super_admin.header)[:items][1..-1]
      user_infos.each do |user|
        if user[:name] != '管理员' then
          user = User.new({:login_name=> user[:pinyin] + '@ee.com',:password=>'111111'}).login
          users << user
          expect(user.errors).to be_nil, "登陆失败， #{user.inspect}"
        end
      end
      login.users = users
      log users.size
    end
  end
 
end
