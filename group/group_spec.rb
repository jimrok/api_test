require './common/login_spec.rb'

users = []
super_admin = nil
group_id = 0
$msgs = []

describe "工作圈创建相关测试" do
  before :each do
    users = Login.instance.users
    super_admin = Login.instance.super_admin
    offline_users = Login.instance.offline_users
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
    r = expect($msgs.count).to eq 1
    r &&= expect($msgs.first[:type]).to eq "sync"
    log colored_str("创建者应收到同步推送", r), 5
    
  end

  it "给工作圈添加成员" do
    $msgs = []
    user_ids = users.inject("") {|sum, n| sum << "#{n.id}," }[0..-2]
    user_id_array = users.map {|user| user.id}

   # for i in 1..users.size-1
   #   user_ids << users[i].account_id.to_s << ','
   #   u << users[i].account_id
   # end
#     user_ids = user_ids[0,user_ids.size-1]
    response = post "/api/v1/groups/#{group_id}/members",{user_ids:user_ids},users[0].header
    log response
    r = expect(response[:meta][:group][:user_ids]).to match_array(user_id_array)
    log colored_str("成员中应包含被添加的人员", r), 5
    sleep 5

    r = expect($msgs.count).to eq(2*(users.count-1))
    log colored_str("被添加的人员都应收到通知", r), 5
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
    r = expect($msgs.count).to eq users.count
    log colored_str("工作圈成员都应收到改名通知", r), 5
  end


  it "删除工作圈的其中一个成员" do
    $msgs = []
    uid = users[users.size-1].id
    u = []
    for i in 0..users.size-2
      u << users[i].id
    end
    response = delete "/api/v1/groups/#{group_id}/members/#{uid}",{} ,users[0].header
    expect(response).to eq "200"
    sleep 2
    r = expect($msgs.count).to eq 1
    log colored_str("被删除的成员应收到通知", r), 5
    $msgs = []
  end

  it "被删除的成员主动加回该工作圈" do 
    response = post "/api/v1/groups/#{group_id}/members",{},users[users.size-1].header
    expect(response[:meta][:group][:id]).to eq group_id
    sleep 2
    r = expect($msgs.count).to eq 1
    r &&= expect($msgs.first[:type]).to eq "private_message"
    log colored_str("工作圈创建者应收到被删除的成员申请加入的通知", r), 5
    $msgs = []
  end

  it "成员主动退出该工作圈" do 
    response = delete "/api/v1/groups/#{group_id}/members",{},users[users.size-1].header
    expect(response).to eq "200"
    sleep 2
    $msgs = []
  end

  it "删除一个工作圈" do
    response = delete "/api/v1/groups/#{group_id}",{} ,users[0].header
    expect(response).to eq "200"
    sleep 5
    r = expect($msgs.count).to eq users.count-1
    $msgs.each {|m| r &&= expect(m[:type]).to eq "sync"}
    log colored_str("工作圈内的成员应收到删除通知", r), 5
    $msgs = []
  end

  it "获取更多的工作圈" do
    response = get '/api/v1/groups', {has_joined_by:users[0].id},users[0].header
    expect(response[:items]).to_not  be_nil
  end

end
