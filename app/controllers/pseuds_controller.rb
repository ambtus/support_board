class PseudsController < ApplicationController

  def show
    @user = User.find_by_login(params[:user_id])
    @pseud = @user.pseuds.where(:name => params[:id])
  end
end
