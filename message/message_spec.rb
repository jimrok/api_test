
require './common/login_spec.rb'

users = []
super_admin = nil

describe "工作圈" do
  before :each do
    users = Login.instance.users
    super_admin = Login.instance.super_admin
  end
  
  it "不登陆无法发送消息" do
    params = {group_id: 7, body: "消息发送应该不成功", threaded: "extended"}
    response = post "/api/v1/messages", params
    expect(response[:errors]).to_not be_nil
  end



  let(:user) {users[0]}
  let(:admin_user) {users[1]}
  
  #   如果有需要可以替换成数据库里已有的两个user，方便在浏览器端查看
#   let(:user) {User.new(USER).login}
#   let(:admin_user) {User.new(ADMIN_USER_BB).login}

  it "有两个用户登陆了系统" do 
    expect(user.response_obj[:errors]).to be_nil, "普通用户登陆失败：#{user.response_obj[:errors]}"
    expect(admin_user.response_obj[:errors]).to be_nil, "管理员用户登陆失败：#{admin_user.response_obj[:errors]}"
    log "登陆成功"
  end

  it "用户可向工作圈中发布、回复消息，点赞、取消赞并能查看到，最后删除" do
    check_send user, admin_user, "消息", 3 do |user, group_id, msg|
      user.send_messege group_id, msg
    end
  end

  it "用户可向工作圈中发布、完成任务、回复消息，点赞、取消赞并能查看到，最后删除" do
    check_send user, admin_user, "任务", 3 do |user, group_id, msg|
      task1 = {due_date:(DateTime.now + 3).to_s,content:"1",checked:"false",assignee_id:admin_user.account_id}
      task2 = {due_date:"",content:"2",checked:"false",assignee_id:admin_user.account_id}
      task3 = {due_date:(DateTime.now + 4).to_s,content:"3",checked:"false",assignee_id:""}
      task4 = {due_date:"",content:"4",checked:"false",assignee_id:""}
      stroy = {app_name: "mini_task", properties: { group_id: group_id, title: msg, check_items: [task1,task2,task3,task4] },threaded: "extended"}
      response = user.create_story_msg group_id, stroy, body: msg
      log response
      items = response[:items]
     #完成任务
      check_items = items[0][:attachments][0][:check_items]
      tid = items[0][:attachments][0][:id]
      log tid.to_s
      check_items.each do |check|
        id = check[:id]
        log id.to_s
        response0 = admin_user.complete_task tid.to_s,id.to_s
        log response0
        expect(response0[:error]).to be_nil
        response0[:items][0][:check_items].each do |c|
          if id == c[:id] then
            expect(c[:checked]).to eq true
            break
          end
        end
      end
      response
    end
  end


  it "用户可向工作圈中发布、回复活动,参加活动，不参加活动，不确定参见活动，点赞，取消赞，并能查看到，最后删除" do
    check_send user, admin_user, "活动", 3 do |user, group_id, msg|
      stroy = {app_name: "event", properties: { description: "活动说明", title: msg, location: "某地点",
                                                start: DateTime.now.to_s, end: (DateTime.now + 3).to_s, 
                                                confirm_end_time: (DateTime.now + 1).to_s
                                              } 
              }
      response = user.create_story_msg group_id, stroy, body: msg
      log response
      items = response[:items]
     #参加活动
      #resp = items[0][:attachments][0][:responses]
      tid = items[0][:attachments][0][:id]
      response0 = user.join_activity tid.to_s,"yes"
      u = [user.account_id]
      log response0
      expect(response0[:responses][:yes][:ids]).to match_array(u)
      response0 = user.join_activity tid.to_s,"no"
      expect(response0[:responses][:no][:ids]).to match_array(u)
      response0 = user.join_activity tid.to_s,"maybe"
      expect(response0[:responses][:maybe][:ids]).to match_array(u)
      response
    end
  end


  it "用户可向工作圈中发布、回复投票,参与投票，点赞，取消赞并能查看到，最后删除帖子" do
    check_send user, admin_user, "投票", 3 do |user, group_id, msg|
      stroy = {app_name: "poll", properties: { title: msg, end_date: (DateTime.now + 3).to_s, 
                                                options: ["选项1", "选项2"]
                                             }
              }
      response = user.create_story_msg group_id, stroy, body: msg
      log response
      items = response[:items]
     #参加投票
      tid = items[0][:attachments][0][:id]
      options = items[0][:attachments][0][:options]
      id = options[0][:index]
      u = [user.account_id]
      response0 = user.vote tid,id.to_s
      options = response0[:options]
      expect(options[0][:users]).to match_array(u)
      response
    end
  end

#   it "管理员可向工作圈中发布、回复公告并能查看到" do
#     check_send admin_user, user, "投票", 3 do |admin_user, group_id, msg|
#       stroy = {app_name: "announcement", properties: { title: msg, content: msg, stick: 0 } }
#       admin_user.create_story_msg group_id, stroy, body: msg
#     end
#   end

#   it "非管理员用户不可向工作圈中发布公告" do
#     group_id = user.joined_groups.first[:id]
#     stroy = {app_name: "announcement", properties: { title: "不应该发送成功", content: "不应该发送成功", stick: 0 } }
#     response = user.create_story_msg group_id, stroy
#     expect(response[:errors]).to_not be_nil
#   end
end




