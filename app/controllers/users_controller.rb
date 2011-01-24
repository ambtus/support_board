class UsersController < ApplicationController

  def show
    @user = User.find_by_login(params[:id])
    raise "no user by that name" unless @user
    if @user.support_identity_id
      @accepted = SupportDetail.where(:resolved_ticket => true).where(:support_identity_id => @user.support_identity_id).count
    end
  end

  def new
    @user = User.new
  end

  def create
    user = User.create!(:login => params[:login],
                 :email => params[:email],
                 :password => "secret",
                 :password_confirmation => "secret")
    user.support_volunteer = "1" unless params[:volunteer].blank?
    user.support_admin = "1" unless params[:admin].blank?
    redirect_to root_path
  end
end
