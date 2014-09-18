require './common/login_spec.rb'

users = []
super_admin = nil
group_id = 0

describe "工作圈创建相关测试" do
  before :each do
    users = Login.instance.users
    super_admin = Login.instance.super_admin
  end

  it "创建一个新的工作圈" do
    $msgs = []
    name = ''
    name << users[0].name << "的工作圈" << rand(999999).to_s
    params = {
      hidden: true,
      limit_size: 0,
      moderated: false,
      name: name,
      public: false
    }
    response = post '/api/v1/groups',params,users[0].header

    expect(response.first[:name]).to eq name
    group_id = response.first[:id]
    sleep 2
    expect($msgs.count).to eq 1
  end

  it "给工作圈添加成员" do
    $msgs = []
    user_ids = ''
    u =[]
    u << users[0].account_id
    for i in 1..users.size-1
      user_ids << users[i].account_id.to_s << ','
      u << users[i].account_id
    end
    user_ids = user_ids[0,user_ids.size-1]
    response = post "/api/v1/groups/#{group_id}/members",{user_ids:user_ids},users[0].header
    log response
    expect(response[:meta][:group][:user_ids]).to match_array(u)
    sleep 5
    expect($msgs.count).to eq(2*(users.count-1))
  end

  it "修改工作圈的名字" do
    $msgs = []
    name = ''
    name << users[0].name << "的工作圈" << rand(999999).to_s
    params = {
      limit_size: 0,
      name: name,
      public: false
    }
    response = put '/api/v1/groups/'+group_id.to_s,params,users[0].header
    sleep 3
    log response
    expect(response[:code]).to eq 200
    expect($msgs.count).to eq users.count
  end


  it "删除工作圈的其中一个成员" do
    $msgs = []
    uid = users[users.size-1].account_id
    u = []
    for i in 0..users.size-2
      u << users[i].account_id
    end
    response = delete "/api/v1/groups/#{group_id}/members/#{uid}",{} ,users[0].header
    expect(response).to eq "200"
    expect($msgs.count).to eq 1
  end

  it "被删除的成员主动加回该工作圈" do 
    response = post "/api/v1/groups/#{group_id}/members",{},users[users.size-1].header
    expect(response[:meta][:group][:id]).to eq group_id
  end

  it "成员主动退出该工作圈" do 
    response = delete "/api/v1/groups/#{group_id}/members",{},users[users.size-1].header
    expect(response).to eq "200"
  end

  it "删除一个工作圈" do
    response = delete "/api/v1/groups/#{group_id}",{} ,users[0].header
    expect(response).to eq "200"
  end

  it "获取更多的工作圈" do
    response = get '/api/v1/groups', {has_joined_by:users[0].account_id},users[0].header
    expect(response[:items]).to_not  be_nil
  end

end
