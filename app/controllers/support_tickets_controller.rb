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

    if is_owner && !params[:support]
      @details = @ticket.support_details.visible_to_all
      @add_details = true # create a new empty response template
      render :show_owner
    elsif !current_user
      @details = @ticket.support_details.visible_to_all
      render :show_guest
    elsif current_user.support_volunteer?
      @details = @ticket.support_details
      @add_details = true # create a new empty response template
      render :show_volunteer
    else # logged in as non-support volunteer
      @details = @ticket.support_details.visible_to_all
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

    # new support ticket
    @ticket = SupportTicket.new(params[:support_ticket])
    @ticket.authenticity_token = params[:authenticity_token]
    @ticket.ip_address = request.remote_ip
    @ticket.user_agent = request.user_agent
    if @ticket.save
      flash[:notice] = "Support ticket created"
      if @ticket.authentication_code
        session[:authentication_code] = @ticket.authentication_code
        Rails.logger.debug "create session: #{session}"
      end
      @ticket.comment!(params[:content], !params[:unofficial])
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
    Rails.logger.debug "update session: #{session}"
    if params[:authentication_code]
      session[:authentication_code] = params[:authentication_code]
    end
    Rails.logger.debug "update fixed session: #{session}"

    # FIXME verify authentication code if no current user
    case params[:commit]
    when "This answer resolves my issue"
      @ticket.accept!(params[:support_detail_id])
    when "Watch this ticket"
      @ticket.watch!
    when "Don't watch this ticket"
      @ticket.unwatch!
    when "Make private"
      @ticket.make_private!
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
      @ticket.reopen!(params[:reason])
    when "Needs admin attention"
      @ticket.needs_admin!
    when "Add details"
      @ticket.comment!(params[:content], params[:official])
    when "Resolve"
      @ticket.resolve!(params[:resolution])
    when "Needs this fix"
      code = @ticket.needs_fix!(params[:code_ticket_id])
      redirect_to edit_code_ticket_path(code) and return
    when "Answered by this FAQ"
      @ticket.answer!(params[:faq_id])
    when "Create new code ticket"
      new = @ticket.needs_fix!
      redirect_to edit_code_ticket_path(new) and return
    when "Create new FAQ"
      new = @ticket.answer!
      redirect_to edit_faq_path(new) and return
    end
    redirect_to @ticket
  end

end
