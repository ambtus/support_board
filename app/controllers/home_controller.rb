class HomeController < ApplicationController

  def index
    @users = User.all
    @volunteers = Role.find_or_create_by_name(:support_volunteer).users
    @support_admins = Role.find_or_create_by_name(:support_admin).users
  end

  def support
  end
end
