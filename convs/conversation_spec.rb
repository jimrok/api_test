require './common/login_spec.rb'

users = []
super_admin = nil

describe "群聊" do
  before :each do
    users = Login.getInstance.users
    super_admin = Login.getInstance.super_admin
  end
  #log Login.getInstance,3
  tc = TalkContent.new
  conversation_id = ''
  it "创建一个聊天室，并邀请所有用户参见进来" do 
    #users = Login.getInstance.users
    direct_to =''
    users.each do |u|
      log u.account_id
      direct_to << u.account_id.to_s << ',' if u.account_id != users[0].account_id
    end
    direct_to = direct_to[0,direct_to.size-1]
    params = {'attached[]'=>'()','body'=>'','direct_to_user_ids'=>direct_to}
    
    response = post '/api/v1/conversations2.json',params,users[0].header
    conversation_id = response[:items][0][:conversation_id]
   # expect(user.response_obj[:errors]).to be_nil, "普通用户登陆失败：#{user.response_obj[:errors]}"
   # expect(admin_user.response_obj[:errors]).to be_nil, "管理员用户登陆失败：#{admin_user.response_obj[:errors]}"
    log "登陆成功"
   
  end

  it "有人在群里说话，其他人应该能收到" do
    req = ''
    req << '/api/v1/conversations2/' << conversation_id.to_s << '/messages'
    csize = rand(tc.size)
    sendMsg = tc.getJsonContent csize
    msg = tc.getContent csize
    response = post req,sendMsg,users[0].header
    req = '/api/v1/conversations2/from_last_seen.json?force_reload=true'
    users.each do |u|
      if u.account_id != users[0].account_id then
        response = get req,{},u.header
        response[:items].each do |conv|
          if conv[:conversation_id] == conversation_id then
            #log '-------->'+conv[:body],3
            expect(conv[:body]).to eq msg
            break;
          end
        end
      end
    end
  end

end








