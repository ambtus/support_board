class UsersController < ApplicationController

  def show
    @user = User.find_by_login(params[:id])
    @accepted = SupportDetail.where(:resolved_ticket => true).where(:pseud_id => @user.pseud_ids).count
  end
end
