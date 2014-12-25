require './common/login_spec.rb'

users = []
offline_users = []
super_admin = nil
$msgs = []

describe "群聊" do
  before :each do
    users = Login.instance.users
    super_admin = Login.instance.super_admin
    offline_users = Login.instance.offline_users
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
   sleep 1

   r = expect($msgs.size).to eq (2 * users.size )
   log colored_str("每个用户应收到一条邀请推送和一条群聊信息推送", r), 5
   $msgs = []
 
  end
  
  conversation_id2 = ''
  it "再次创建一个包含相同用户的群聊，应视作不同的群聊" do 
   $msgs = []
   user_ids = users.map {|u| u.id}
   response = users.first.direct_send_minxin(user_ids, "", {})
   conversation_id2 = response[:items][0][:conversation_id]
   expect(conversation_id2).not_to eq conversation_id
   sleep 1

   r = expect($msgs.size).to eq(2 * users.size )
   log colored_str("每个用户应收到一条邀请推送和一条群聊信息推送", r), 5
   $msgs = []
  end

  it "用户向群聊发送消息，除自己外，其他在线用户每人应收到推送" do
    5.times do |time|
      $msgs = []
      msg = tc.get_random_content
      response = users[rand(users.count)].send_minxin_by_conversation_id conversation_id, msg
      expect(response[:errors]).to be_nil
      sleep 1

#       puts $msgs.inspect
      expect($msgs.count).to eq(users.count - 1)

      correct_msgs = $msgs.select { |m| msg == m[:data][:body] }
      expect(correct_msgs.size).to eq $msgs.size
    end
   $msgs = []
  end

  it "用户A修改群聊名称，包括自己在内的所有人都应收到改名的系统消息和同步推送" do
    $msgs = []
    put "/api/v1/conversations/#{conversation_id}", {name: "changed_name"}, users.first.header
    sleep 1
    expect($msgs.count).to eq(2*users.count)
    $msgs = []
  end

  it "A邀请另一个用户D加入群聊，该用户D及群聊中已有用户都应收到推送，" do
    ano_user = offline_users.first.login
    ano_user.receive_mqtt do |topic, msg|
      m = JSON.parse(msg, symbolize_names: true)
      ano_user.messages << m
      $msgs << m
    end
    sleep 1
    $msgs = []
    users << ano_user

    url = "/api/v1/conversations/#{conversation_id}/users"
    response = post url, {user_id: "#{ano_user.id}"}, users.first.header
    expect(response[:errors]).to be_nil
    sleep 1

    expect($msgs.count).to eq(2 * (users.count) )
    $msgs = []
  end

  it "用户D向群聊发送消息，其他在线用户每人应收到推送" do
    3.times do |time|
      $msgs = []
      msg = tc.get_random_content
      response = offline_users.first.send_minxin_by_conversation_id conversation_id, msg
      expect(response[:errors]).to be_nil
      sleep 1

      expect($msgs.count).to eq(users.count - 1)

      correct_msgs = $msgs.select { |m| msg == m[:data][:body] }
      expect(correct_msgs.size).to eq $msgs.size
    end
  end

   it "用户D向群聊发送一张图片，其他在线用户每人应收到推送" do
     $msgs = []
     pics = Dir["./files/pic/*"]
     pic_name = pics[rand pics.size]
     
     response = offline_users.first.send_pic_to_conversation pic_name, conversation_id
     expect(response[:errors]).to be_nil
     sleep 1
 
     $msgs.each do |msg|
       expect(msg[:data][:image_base64]).to_not be_nil
     end
 
     expect($msgs.count).to eq(users.count - 1)
 
 #     correct_msgs = $msgs.select { |m| msg == m[:data][:body] }
 #     expect(correct_msgs.size).to eq $msgs.size
   end

  # it "在线用户拉取消息，不应重复拉取已经接收的消息" do
  #   users.each do |user|
  #     puts user.from_last_seen

  #   end
  # end


end
