require './common/login_spec.rb'

users = []
super_admin = nil
msgs = []

describe "群聊" do
  before :each do
    users = Login.instance.users
    super_admin = Login.instance.super_admin
  end
  #log Login.instance,3
  tc = TalkContent.new
  conversation_id = ''
  it "创建一个群聊，并邀请所有用户参与进来" do 
    #users = Login.instance.users
   # direct_to =''
   # users.each do |u|
   #   log u.account_id
   #   direct_to << u.account_id.to_s << ',' if u.account_id != users[0].account_id
   # end
   # direct_to = direct_to[0,direct_to.size-1]
   # params = {'attached[]'=>'()','body'=>'','direct_to_user_ids'=>direct_to}
   # 
   # response = post '/api/v1/conversations.json',params,users[0].header
   # conversation_id = response[:items][0][:conversation_id]
   $msgs = []
   user_ids = users.map {|u| u.id}
   response = users.first.direct_send_minxin(user_ids, "", {})
   conversation_id = response[:items][0][:conversation_id]
   expect(conversation_id).not_to be_nil
   sleep 5

   r = expect($msgs.size).to eq (2 * users.size )
   log colored_str("每个用户应收到一条邀请推送和一条群聊信息推送", r), 5
 
  end
  
  conversation_id2 = ''
  it "再次创建一个包含相同用户的群聊，应视作不同的群聊" do 
   $msgs = []
   user_ids = users.map {|u| u.id}
   response = users.first.direct_send_minxin(user_ids, "", {})
   conversation_id2 = response[:items][0][:conversation_id]
   expect(conversation_id2).not_to eq conversation_id
   sleep 5

   expect($msgs.size).to eq (2 * users.size )
   r = expect($msgs.size).to eq (2 * users.size )
   log colored_str("每个用户应收到一条邀请推送和一条群聊信息推送", r), 5
  end

  it "用户向群聊发送5条消息，其他在线用户每人应收到5条推送" do
    5.times do |time|
      $msgs = []
      msg = tc.get_random_content
      response = users[rand(users.count)].send_minxin_by_conversation_id conversation_id, msg
      expect(response[:errors]).to be_nil
      sleep 5

      expect($msgs.count).to eq(users.count - 1)

      correct_msgs = $msgs.select { |m| msg == m[:data][:body] }
      expect(correct_msgs.size).to eq $msgs.size
    end
  end

  # it "在线用户拉取消息，不应重复拉取已经接收的消息" do
  #   users.each do |user|
  #     puts user.from_last_seen

  #   end
  # end


end
