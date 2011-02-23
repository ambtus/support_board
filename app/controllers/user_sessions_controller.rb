class UserSessionsController < ApplicationController
  skip_before_filter :store_location

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      @current_user = @user_session.record
      flash[:notice] = "Hi, #{current_user.login}!"
      session.delete(:authentication_code)
      redirect_back_or_default
    else
      # reset user session so errors don't indicate where the problem is
      @user_session = UserSession.new(params[:user_session])
      flash[:error] = "Sorry"
      render :new
    end
  end

  def destroy
    @user_session = UserSession.find
    if @user_session
      flash[:notice] = "Bye, #{current_user.login}!"
      @user_session.destroy
    end
    redirect_back_or_default root_url
  end

end
