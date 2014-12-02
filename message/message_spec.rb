
require './common/login_spec.rb'

users = []
super_admin = nil
$msgs = []

describe "工作圈" do
  before :each do
    users = Login.instance.users
    super_admin = Login.instance.super_admin
    offline_users = Login.instance.offline_users
  end

  it "不登陆无法发送消息" do
    params = {group_id: 7, body: "消息发送应该不成功", threaded: "extended"}
    response = post "/api/v1/messages", params
    expect(response[:errors]).to_not be_nil
  end



  let(:user) {users[0]}
  let(:user2) {users[1]}

  #   如果有需要可以替换成数据库里已有的两个user，方便在浏览器端查看
  #   let(:user) {User.new(USER).login}
  #   let(:user2) {User.new(ADMIN_USER_BB).login}

  it "有两个用户登陆了系统" do 
    expect(user.response_obj[:errors]).to be_nil, "普通用户登陆失败：#{user.response_obj[:errors]}"
    expect(user2.response_obj[:errors]).to be_nil, "管理员用户登陆失败：#{user2.response_obj[:errors]}"
    log "登陆成功"
  end

  it "用户可向工作圈中发布、回复消息，点赞、取消赞并能查看到，最后删除" do
    check_send users, "消息", 3
  end

  it "用户可向工作圈中发布、完成任务、回复消息，点赞、取消赞并能查看到，最后删除" do
    check_send users, "任务", 3 do |user, group_id, msg|
      task1 = {due_date: (DateTime.now + 3).to_s, content: "1", checked: "false", assignee_id: user2.id}
      task2 = {due_date: "", content: "2", checked: "false", assignee_id: user2.id}
      task3 = {due_date: (DateTime.now + 4).to_s, content:"3", checked:"false", assignee_id:""}
      task4 = {due_date: "", content: "4", checked: "false", assignee_id: ""}
      stroy = {app_name: "mini_task", threaded: "extended", 
               properties: { group_id: group_id, title: msg, check_items: [task1,task2,task3,task4] }}

      $msgs = []
      response = user.create_story_msg group_id, stroy, body: msg
      r = expect(response[:errors]).to be_nil
      log response
      items = response[:items]
      log colored_str("用户A创建4个任务，并指派两个任务给用户B。", r), 5
      sleep 2

      private_messages = $msgs.select {|m| m[:type] == "private_message"}
      notifies = $msgs.select {|m| m[:type] == "notification"}
      r = expect(private_messages.count).to eq 2
      r &= expect(notifies.count).to eq users.count
      log colored_str("用户B收到两条通知消息，其他用户收到小红点消息。", r), 5


      $msgs = []
      #完成任务
      check_items = items[0][:attachments][0][:check_items]
      tid = items[0][:attachments][0][:id]
      log tid.to_s
      check_items.each do |check|
        id = check[:id]
        log id.to_s
        response0 = user2.complete_task tid.to_s,id.to_s
        log response0
        r = expect(response0[:error]).to be_nil
        response0[:items][0][:check_items].each do |c|
          if id == c[:id] then
            r &= expect(c[:checked]).to eq true
            break
          end
        end
      end
      log colored_str("用户B完成全部4个任务", r), 5
      sleep 5

      r = expect($msgs.count).to eq 4
      $msgs.each do |m|
        r &= expect(m[:data][:direct_to_user_id]).to eq user.id
      end
      log colored_str("用户A应收到4条通知消息", r), 5

      $msgs = []
      response
    end
  end


  it "用户可向工作圈中发布、回复活动,参加活动，不参加活动，不确定参加活动，点赞，取消赞，并能查看到，最后删除" do
    check_send users, "活动", 3 do |user, group_id, msg|
      stroy = {app_name: "event", properties: { description: "活动说明", title: msg, location: "某地点",
                                                start: DateTime.now.to_s, end: (DateTime.now + 3).to_s, 
                                                confirm_end_time: (DateTime.now + 1).to_s
        }
      }
      response = user.create_story_msg group_id, stroy, body: msg
      r = expect(response[:errors]).to be_nil
      log response
      items = response[:items]
      log colored_str("用户A创建活动", r), 5
      #参加活动
      #resp = items[0][:attachments][0][:responses]
      tid = items[0][:attachments][0][:id]
      response0 = user.join_activity tid.to_s,"yes"
      r = expect(response0[:responses][:yes][:ids]).to match_array([user.id])
      log colored_str("用户A参加活动，活动的参加者中应有A", r), 5

      response0 = user2.join_activity tid.to_s,"no"
      r = expect(response0[:responses][:no][:ids]).to match_array([user2.id])
      log colored_str("用户B不参加活动，活动的不参加者中应有B", r), 5

      response0 = user.join_activity tid.to_s,"maybe"

      #NOTE: 用to_not时，断言的结果与expect的返回值正好相反，所以这里对r2取反。
      r1 = expect(response0[:responses][:maybe][:ids]).to match_array([user.id])
      r2 = expect(response0[:responses][:yes][:ids]).to_not match_array([user.id])
      r = r1 && !r2

      log colored_str("用户A改为不确定，不确定参加者中应有A, 参加者中应没有A", r), 5
      response
    end
  end


  it "用户可向工作圈中发布、回复投票,参与投票，点赞，取消赞并能查看到，最后删除帖子" do
    check_send users, "投票", 3 do |user, group_id, msg|
      stroy = {app_name: "poll", properties: {title: msg, end_date: (DateTime.now + 3).to_s, options: ["选项1", "选项2"]}}
      response = user.create_story_msg group_id, stroy, body: msg
      log response
      items = response[:items]
      r = expect(response[:errors]).to be_nil
      log colored_str("用户A创建投票", r), 5
      #参加投票
      tid = items[0][:attachments][0][:id]
      options = items[0][:attachments][0][:options]
      id = options[0][:index]
      u = [user.id, user2.id]
      response0 = user.vote tid,id.to_s
      response0 = user2.vote tid,id.to_s
      options = response0[:options]
      r = expect(options[0][:users]).to match_array(u)
      log colored_str("用户AB均参加投票，相应选项投票记录应包含AB", r), 5
      response
    end
  end

  #   it "管理员可向工作圈中发布、回复公告并能查看到" do
  #     check_send user2, user, "投票", 3 do |user2, group_id, msg|
  #       stroy = {app_name: "announcement", properties: { title: msg, content: msg, stick: 0 } }
  #       user2.create_story_msg group_id, stroy, body: msg
  #     end
  #   end

  #   it "非管理员用户不可向工作圈中发布公告" do
  #     group_id = user.joined_groups.first[:id]
  #     stroy = {app_name: "announcement", properties: { title: "不应该发送成功", content: "不应该发送成功", stick: 0 } }
  #     response = user.create_story_msg group_id, stroy
  #     expect(response[:errors]).to_not be_nil
  #   end
end




