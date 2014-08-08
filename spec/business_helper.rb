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
  def check_send user1, user2, type, wait_seconds
    group_id = user1.joined_groups.first[:id]
    #     查看工作圈消息
    user_messages = user1.view_group group_id
    expect(user_messages[:error]).to be_nil, "查看#{type}失败：#{user_messages[:error]}"

    test_msg = "用户#{user1.name}发送测试#{type}#{(1000 * rand).to_i}"
    # 如果指定了块，则按照块内步骤操作，否则发送普通消息
    response =  if block_given? 
                  yield(user1, group_id, test_msg)
                else
                  user1.send_messege(group_id, test_msg)
                end
    expect(response[:errors]).to be_nil, "#{user1.name}发送测试#{type}失败,#{response}"
    thread_id = response[:items].first[:id]

    log "发送测试#{type}成功: #{test_msg}"

    log "等待#{wait_seconds}秒"
    sleep wait_seconds

    # 查看工作圈，刚才的发送是否成功
    user2_messages = user2.view_group group_id
    response_msg = user2_messages[:items].first[:body][:plain]
#     puts user2_messages[:items].first

    expect(response_msg).to eq(test_msg), "期望为#{test_msg}, 实际为#{response_msg}"
    log "#{user2.name}在组里查看#{type}成功"


    test_reply_msg = "用户#{user2.name}测试回复#{type}#{(1000 * rand).to_i}"
    # 回复刚才的消息
    response = user2.send_messege(group_id, test_reply_msg, replied_to_id: thread_id )
    expect(response[:errors]).to be_nil, "回复#{type}失败,#{response}"
    log "#{user2.name}回复#{type}成功，等待#{wait_seconds}秒"
    sleep wait_seconds

    # 查看工作圈，刚才的回复是否成功
    user_messages = user1.view_group group_id
    ids = []
    threaded_extendeds = user_messages[:threaded_extended]
    threaded_extendeds.each {|k, v| ids << k.to_s.to_i }
    reply_id = ids.max.to_s.to_sym

    response_msg = threaded_extendeds[reply_id].first[:body][:plain]
    expect(response_msg).to eq(test_reply_msg), "期望为#{test_reply_msg}, 实际为#{response_msg}"
    log "#{user1.name}查看回复#{type}成功"
  end
end
