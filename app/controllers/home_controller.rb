class HomeController < ApplicationController

  def index
    @support_admins = Role.find_or_create_by_name(:support_admin).users
    @volunteers = Role.find_or_create_by_name(:support_volunteer).users - @support_admins
    @users = User.all - @volunteers - @support_admins
  end

  def support
  end
end
