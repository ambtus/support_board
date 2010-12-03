class AdminSessionsController < ApplicationController
  skip_before_filter :store_location

  def create
    @admin_session = AdminSession.new(params[:admin_session])
    if @admin_session.save
      @current_admin = @admin_session.record
      flash[:notice] = "Hi, #{current_admin.login}!"
      redirect_back_or_default
    else
      # reset admin session so errors don't indicate where the problem is
      @admin_session = AdminSession.new(params[:admin_session])
      render :new
    end
  end

  def destroy
    @admin_session = AdminSession.find
    if @admin_session
      flash[:notice] = "Bye, #{current_admin.login}!"
      @admin_session.destroy
    end
    redirect_back_or_default root_url
  end

end
