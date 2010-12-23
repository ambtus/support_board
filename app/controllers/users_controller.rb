class UsersController < ApplicationController

  def show
    @user = User.find_by_login(params[:id])
    if @user.support_identity_id
      @accepted = SupportDetail.where(:resolved_ticket => true).where(:support_identity_id => @user.support_identity_id).count
    end
  end
end
