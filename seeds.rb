#encoding=utf-8
#
def random_num
  (10000000 * rand).to_i
end

module Seeds
  SUPER_ADMIN = {login_name: "admin", password: "workasadmin001"}

  ADMIN_USER_BB = { login_name: "admin@bb", password: "111111" }
  USER = { login_name: "wang@t.com", password: "222222", email: "wang@t.com", name: "老王"}
  USER2 = { login_name: "li@t.com", password: "333333", email: "li@t.com", name: "老李"}

  n = random_num
  RANDOM_USER_1 ||= {login_name: "rand_user_#{n}", password: "111111", email: "rand_#{n}@rand.com", name: "员工#{n}"}
  n = random_num
  RANDOM_USER_2 ||= {login_name: "rand_user_#{n}", password: "111111", email: "rand_#{n}@rand.com", name: "员工#{n}"}

  n = random_num
  RANDOM_NETWORK ||= {name: "rand_group_#{n}.com", display_name: "随机工作圈_#{n}"}

  n = random_num
  RANDOM_DEPT ||= {short_name: "short_#{n}", full_name: "full_#{n}", dept_code: "code_#{n}"}

  n = random_num
  RANDOM_GROUP ||= {}

  def get_a_random_user n
    random_user = {login_name: "rand_user_#{n}", password: "111111", email: "rand_#{n}@rand.com", name: "员工#{n}"}
    random_user
  end

  NETWORK_1 ||= {id:9, name: "rand_group_4840479.com"}
end
