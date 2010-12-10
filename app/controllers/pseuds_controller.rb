class PseudsController < ApplicationController

  def show
    @user = User.find_by_login(params[:user_id])
    @pseud = @user.pseuds.where(:name => params[:id]).first
  end
  def index
    @user = User.find_by_login(params[:user_id])
  end
end
