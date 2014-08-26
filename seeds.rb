#encoding=utf-8
#
def random_num
  (10000000 * rand).to_i
end

module Seeds
  SUPER_ADMIN = {login_name: "admin", password: "workasadmin001"}

  ADMIN_USER_BB = { login_name: "0001@minxing.com", password: "111111" }
  USER = { login_name: "0001@minxing.com", password: "111111", email: "0001@minxing.com", name: "老王"}
  USER2 = { login_name: "0002@minxing.com", password: "111111", email: "0002@minxing.com", name: "老李"}

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

  NETWORK_1 ||= {id:2, name: "rand_group_4840479.com"}
end
