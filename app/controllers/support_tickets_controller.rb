class SupportTicketsController < ApplicationController
  skip_before_filter :store_location, :only => [:new]

  def index
    begin
      @tickets = SupportTicket.filter(params)
    rescue SecurityError
      flash[:error] = "Please log in"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Please check your spelling"
    end
    unless @tickets
      @tickets = []
    end
  end

  def comments
    @tickets = SupportTicket.filter(:status => "posted")
  end

  def show
    if params[:authentication_code]
      session[:authentication_code] = params[:authentication_code]
    end
    Rails.logger.debug "show support ticket session: #{session}"
    @ticket = SupportTicket.find(params[:id])
    is_owner = @ticket.owner?(session[:authentication_code]) # is viewer owner of ticket?

    if @ticket.private && (!is_owner && !current_user.try(:support_volunteer?))
      flash[:error] = "Sorry, you don't have permission to view this ticket"
      redirect_to support_path and return
    end

    @details = @ticket.visible_support_details

    if is_owner && !params[:support]
      @add_details = true # create a new empty response template
      render :show_owner
    elsif !current_user
      render :show_guest
    elsif current_user.support_volunteer?
      @add_details = true # create a new empty response template
      render :show_volunteer
    else # logged in as non-support volunteer
      if !@ticket.support_identity_id # if support took it, it's not longer open for public comment
        @add_details = true # create a new empty response template
      end
      render :show_user
    end
  end

  def new
    @ticket = SupportTicket.new
    @add_details = true # create a new empty response template
  end

 def create
    # send a guest links to their tickets
    if params[:email]
      @tickets = SupportTicket.where(:email => params[:email])
      if @tickets.count > 0
        SupportTicketMailer.send_links(params[:email], @tickets).deliver
        flash[:notice] = "Email sent"
      else
        flash[:error] = "Sorry, no support tickets found for " + params[:email]
      end
      redirect_to support_path and return
    end

    @ticket = SupportTicket.new(params[:support_ticket].merge({
         :authenticity_token => params[:authenticity_token],
         :ip_address => request.remote_ip,
         :user_agent => request.user_agent,
         :no_comments => params[:content].blank?}))

    if @ticket.save
      flash[:notice] = "Support ticket created"
      if current_user
        @ticket.user_comment!(params[:content], !params[:unofficial])
      else
        @ticket.guest_owner_comment!(params[:content], @ticket.authentication_code)
        session[:authentication_code] = @ticket.authentication_code
        Rails.logger.debug "create session: #{session}"
      end
      redirect_to @ticket
    else
      # reset so don't get field with errors which breaks definition lists
      flash[:error] = @ticket.errors.full_messages.join(", ")
      @ticket = SupportTicket.new(params[:support_ticket])
      render :new
    end
  end

  def update
    @ticket = SupportTicket.find(params[:id])

    # this, and the corresponding hidden field in show_owner.html shouldn't be needed
    # but capybara is loosing the session information for some reason when posting
    Rails.logger.debug "session: #{session}"
    if params[:authentication_code]
      session[:authentication_code] = params[:authentication_code]
    end
    Rails.logger.debug "fixed session: #{session}"

    case params[:commit]
    when "This answer resolves my issue"
      @ticket.accept!(params[:support_detail_id], session[:authentication_code])
    when "Watch this ticket"
      @ticket.watch!(session[:authentication_code])
    when "Don't watch this ticket"
      @ticket.unwatch!(session[:authentication_code])
    when "Make private"
      @ticket.make_private!(session[:authentication_code])
    when "Hide my user name"
      @ticket.hide_username!
    when "Display my user name"
      @ticket.show_username!
    when "Take"
      @ticket.take!
    when "Steal"
      @ticket.steal!
    when "Send request to take"
      @ticket.give!(params[:support_identity_id])
    when "Mark as ham"
      @ticket.ham!
    when "Mark as spam"
      @ticket.spam!
    when "Post as comment"
      @ticket.post!
    when "Reopen"
      @ticket.reopen!(params[:reason], session[:authentication_code])
    when "Needs admin attention"
      @ticket.needs_admin!
    when "Add details"
      if current_user
        @ticket.user_comment!(params[:content], params[:response])
      else
        @ticket.guest_owner_comment!(params[:content], session[:authentication_code])
      end
    when "Resolve"
      @ticket.resolve!(params[:resolution])
    when "Needs this fix"
      code = @ticket.needs_fix!(params[:code_ticket_id])
    when "Answered by this FAQ"
      @ticket.answer!(params[:faq_id])
    when "Create new code ticket"
      new = @ticket.needs_fix!
      redirect_to edit_code_ticket_path(new) and return
    end
    redirect_to @ticket
  end

end
