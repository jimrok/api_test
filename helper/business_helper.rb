#encoding=utf-8
require 'rubygems'
require 'mqtt'
module BusinessHelper
  # 与工作圈相关的测试步骤
  # 场景：用户A、B
  # 行为：1、用户A查看他的第一个工作圈
  #       2、如果指定了块，则按照块中方法操作，否则向此工作圈中发送一个消息
  #       3、用户2查看此工作圈，应能看到第2步发送的消息
  #       4、用户2回复这条消息
  #       5、用户1查看回复
  # =>    6.用户2点赞 用户2取消赞
  # =>    7。用户1删除帖子
  def check_send users, type, wait_seconds
    $msgs = []
    user1, user2 = users[0..1]
    group_id = user1.joined_groups.first[:id]
    test_msg = "用户#{user1.name}发送测试#{type}#{(1000 * rand).to_i}"

    #     查看工作圈消息
    explore_messages user1,group_id ,type

    # 如果指定了块，则按照块内步骤操作，否则发送普通消息
    response = if block_given? 
                 yield(user1, group_id, test_msg)
               else
                 response = user1.send_messege(group_id, test_msg)
                 r = expect(response[:errors]).to be_nil, "#{user1.name}发送测试#{type}失败,#{response}"
                 thread_id = response[:items].first[:id]
                 log response
                 log colored_str("发送测试#{type}成功: #{test_msg}", r), 5

                 log "等待#{wait_seconds}秒"
                 sleep wait_seconds
                 r = expect($msgs.count).to eq users.count
                 $msgs.each {|msg| r &&= expect(msg[:type]).to eq "notification"}
                 log colored_str("发送消息后，客户端应接收到小红点的信息推送", r), 5
                 response
               end


    thread_id = response[:items].first[:id]
    # 查看工作圈，刚才的发送是否成功
    sleep 3
    $msgs = []
    explore_messages user2,group_id, type,test_msg
    #回复帖子
    test_reply_msg = reply_message user2, group_id,type, thread_id
    sleep 2

    notifications = $msgs.select {|msg| msg[:type] == "notification"}
    mes = $msgs.select {|msg| msg[:type] == "private_message"}

    r = expect(mes.count).to eq 1
    r &&= expect(mes.first[:data][:direct_to_user_id]).to eq user1.id
    log colored_str("对#{type}进行回复，作者应能收到私信通知", r), 5
    
    r = expect(notifications.count).to eq users.count
    log colored_str("对#{type}进行回复，其他人应能收到小红点通知", r), 5

    $msgs = []
    #点赞
    response = user2.send_like(message_id:thread_id)
    expect(response[:message]).to eq 'liked'

    sleep wait_seconds
    r = expect($msgs.count).to eq 1
    r &&= expect($msgs.first[:data][:direct_to_user_id]).to eq user1.id
    log colored_str("对#{type}进行点赞，作者应能收到私信通知", r), 5

    # 查看工作圈，刚才的回复是否成功
    explore_reply_messages user1,user2,group_id,type,test_reply_msg
    $msgs = []


    share_id = share_message user2,group_id,type,"分享#{test_msg}",thread_id
    sleep 3
    r = true
    $msgs.each {|msg| r &&= expect(msg[:type]).to eq "notification"}
    log colored_str("对#{type}进行分享，应收到小红点通知", r), 5


    $msgs = []


    #取消赞
    response = user2.send_unLike(message_id:thread_id)
    r = expect(response).to eq "200"
    log colored_str("应能正确取消赞", r), 5

    sleep wait_seconds
    #     puts $msgs.inspect
    #     notifications = $msgs.select {|msg| msg[:type] == "notification"}
    #     expect(notifications.count).to eq users.count
    $msgs = []

    #删除帖子
    response = user1.delete_message thread_id
    r = expect(response).to eq "200"
    log colored_str("应能正确删除帖子", r), 5

    sleep wait_seconds

    #删除分享
    response = user2.delete_message share_id
    r = expect(response).to eq "200"
    log colored_str("应能正确删除分享", r), 5
    sleep 2
  end

  def explore_messages user1,group_id,type,test_msg = nil
    user_messages = user1.view_group group_id
    r = expect(user_messages[:error]).to be_nil, "查看#{type}失败：#{user_messages[:error]}"
    if test_msg
      response_msg = user_messages[:items].first[:body][:plain]
      #     puts user2_messages[:items].first
      r &&= expect(response_msg).to eq(test_msg), "期望为#{test_msg}, 实际为#{response_msg}"
      log colored_str("客户端应能查看到新消息", r), 5
    end
  end

  def reply_message user2,group_id,type,thread_id
    test_reply_msg = "用户#{user2.name}测试回复#{type}#{(1000 * rand).to_i}"
    # 回复刚才的消息
    response = user2.send_messege(group_id, test_reply_msg, replied_to_id: thread_id )
    expect(response[:errors]).to be_nil, "回复#{type}失败,#{response}"
    log "#{user2.name}回复#{type}成功"
    sleep 3
    test_reply_msg
  end

  def explore_reply_messages user1,user2,group_id,type,test_reply_msg
    user_messages = user1.view_group group_id
    ids = []
    threaded_extendeds = user_messages[:threaded_extended]

    threaded_extendeds.each {|k, v| ids << k.to_s.to_i }
    reply_id = ids.max.to_s.to_sym

    response_msg = threaded_extendeds[reply_id].first[:body][:plain]
    r = expect(response_msg).to eq(test_reply_msg), "期望为#{test_reply_msg}, 实际为#{response_msg}"
    log "#{user1.name}查看回复#{type}成功"
    items = user_messages[:items]
    liked_by = items.first[:liked_by][:ids].first

    r &&= expect(liked_by).to eq user2.id 
    log colored_str("客户端应能查看到回复消息及点赞状态", r), 5
  end

  def share_message user2,group_id,type,body,thread_id
    response = user2.send_messege(group_id, body, {"attached[]"=>"()",shared_message_id:thread_id} )
    log response
    expect(response[:items][0][:shared_message_id]).to eq thread_id
    response[:items][0][:id]
  end

end
