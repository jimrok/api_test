require './common/login_spec.rb'

users = []
super_admin = nil

describe "这是一个样例" do
  before :each do
    users = Login.instance.users
    super_admin = Login.instance.super_admin
  end
  
  it "是测试的方法1" do
    
  end
  
  it "是测试的方法2" do
    
  end
end
