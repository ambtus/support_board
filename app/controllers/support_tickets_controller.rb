class SupportTicketsController < ApplicationController
  skip_before_filter :store_location, :only => [:new]

  def index
    # start a scope
    @tickets = SupportTicket.scoped

    owner = params[:user_id] ? User.find_by_login(params[:user_id]) : false

    # if not support volunteer, and not looking at list of own tickets, rule out private tickets
    if !current_user.try(:support_volunteer?) && current_user != owner
      @tickets = @tickets.where(:private => false)
    end

    # tickets associated with a user
    if params[:user_id]
      raise "no such user" unless owner
      # tickets I commented on
      if params[:comments]
        @tickets = @tickets.joins(:support_details) & SupportDetail.where(:support_identity_id => owner.support_identity_id)

      # tickets I am watching, private
      elsif params[:watching]
        if current_user != owner
          flash[:error] = "Sorry, you don't have permission"
          redirect_back_or_default
        else
          @tickets = @tickets.joins(:support_notifications) & SupportNotification.where(:email => owner.email)
        end

      # support volunteer's tickets
      elsif params[:support]
        @tickets = @tickets.where(:support_identity_id => owner.support_identity_id)
        case params[:status]
        when "closed"
          @tickets = @tickets.closed
        when "waiting"
          @tickets = @tickets.waiting
        when "taken"
          @tickets = @tickets.taken
        end
        render :index and return

      # tickets I opened
      else
        @tickets = @tickets.where(:user_id => owner.id)
        if current_user != owner
          # if not owner, can only see tickets where name is displayed
          @tickets = @tickets.where(:display_user_name => true)
        end
      end

    # specific support tickets
    elsif params[:status]
      case params[:status]
      when "taken"
        @tickets = @tickets.taken
      when "admin"
        @tickets = @tickets.waiting_on_admin
      when "posted"
        @tickets = @tickets.posted
        # render a more friendly index page
        render :posted_index and return
      when "waiting"
        @tickets = @tickets.waiting
      when "spam"
        @tickets = @tickets.spam
        # render now, because we add not spam later
        render :index and return
      when "closed"
        @tickets = @tickets.closed
        # render now, because we add not not resolved later
        render :index and return
      end

    # default - unowned tickets
    else
      @tickets = @tickets.unowned
    end

    # if we haven't rendered before this, rule out closed tickets and spam
    @tickets = @tickets.not_closed
  end

  def show
    if params[:authentication_code]
      session[:authentication_code] = params[:authentication_code]
    end
    Rails.logger.debug "show session: #{session}"
    @ticket = SupportTicket.find(params[:id])
    is_owner = @ticket.owner?(session[:authentication_code]) # is viewer owner of ticket?

    if @ticket.private && (!is_owner && !current_user.try(:support_volunteer?))
      flash[:error] = "Sorry, you don't have permission to view this ticket"
      redirect_to support_path and return
    end

    if is_owner
      @details = @ticket.support_details.not_private
      @add_details = true # create a new empty response template
      render :show_owner
    elsif !current_user
      @details = @ticket.support_details.not_private
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
    @ticket.support_details.build # create a new empty response template
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
    if @ticket.save
      flash[:notice] = "Support ticket created"
      if @ticket.authentication_code
        session[:authentication_code] = @ticket.authentication_code
        Rails.logger.debug "create session: #{session}"
      end
      redirect_to @ticket
      @ticket.send_create_notifications
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

    case params[:commit]
    when "This answer resolves my issue"
      @ticket.accept!(params[:support_detail_id], params[:email])
    when "Watch this ticket"
      @ticket.watch!(params[:email])
    when "Don't watch this ticket"
      @ticket.unwatch!(params[:email])
    when "Make private"
      @ticket.make_private!(params[:email])
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
      @ticket.reopen!(params[:reason], params[:email])
    when "Needs admin attention"
      @ticket.needs_admin!
    when "Add details"
      @ticket.comment!(params[:content], params[:official], params[:email])
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
