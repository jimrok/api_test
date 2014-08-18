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


describe "用户" do
  login = Login.getInstance
  it "管理员登陆" do
    super_admin = User.new({:login_name=>'admin@minxing',:password=>'111111'}).login
    login.super_admin = super_admin
    
  end
  
  describe do
    it "获取用户列表,并登录" do
    #let(:users) do
      response = get '/api/v1/users.json', {:page=>1,:limit=>4},super_admin.header
      response[:items].each do |user|
        if user[:name] != '管理员' then
          user = User.new({:login_name=> user[:name] + '@minxing.com',:password=>'111111'}).login
          users << user
        end
      end
      login.users = users
      log users.size
    end
  end
 
end
