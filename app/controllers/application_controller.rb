class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :app_version

  def app_version
    @app_version || ReleaseNote.last.try(:release)
  end

  helper_method :current_user
  before_filter :store_location

  # Store the current user in the User class as User.current_user
  before_filter :set_current_user
  def set_current_user
    User.current_user = current_user
  end

  # store previous page in session to make redirecting back possible
  def store_location
    if session[:return_to] == "redirected"
      Rails.logger.debug "Return to back would cause infinite loop, unsetting return_to"
      session.delete(:return_to)
    else
      session[:return_to] = request.fullpath
      Rails.logger.debug "Return to: #{session[:return_to]}"
    end
  end

  # try redirect back to referring page, otherwise go to a designated default
  def redirect_back_or_default(default = root_path)
    back = session[:return_to]
    session.delete(:return_to)
    if back
      Rails.logger.debug "Returning to #{back}"
      session[:return_to] = "redirected"
      redirect_to(back) and return
    else
      Rails.logger.debug "Returning to default (#{default})"
      redirect_to(default) and return
    end
  end

protected
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
  end

end


