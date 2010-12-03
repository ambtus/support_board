class UserSessionsController < ApplicationController
  skip_before_filter :store_location

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Successfully logged in."
      @current_user = @user_session.record
    else
      flash[:error] = "Sorry"
    end
    redirect_back_or_default
  end
end
