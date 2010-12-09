class SupportTicketsController < ApplicationController

  def index
    # start a scope
    @tickets = SupportTicket.scoped

    owner = params[:user_id] ? User.find_by_login(params[:user_id]) : false

    # if not support volunteer, and not looking at list of own tickets, rule out private tickets
    if !current_user.try(:support_volunteer) && current_user != owner
      @tickets = @tickets.where(:private => false)
    end

    # support volunteer's working tickets
    if params[:pseud_id]
      pseud = Pseud.find_by_name(params[:pseud_id])
      @tickets = @tickets.where(:pseud_id => pseud.id)

    # tickets associated with a user
    elsif params[:user_id]
      # tickets I commented on
      if params[:comments]
        @tickets = @tickets.joins(:support_details) & SupportDetail.where(:pseud_id => owner.pseud_ids)

      # tickets I am watching, private
      elsif params[:watching]
        if current_user != owner
          flash[:error] = "Sorry, you don't have permission"
          redirect_back_or_default
        else
          @tickets = @tickets.joins(:support_notifications) & SupportNotification.where(:email => owner.email)
        end

      # tickets I opened
      else
        @tickets = @tickets.where(:user_id => owner.id)
        if current_user != owner
          # if not owner, can only see tickets where name is displayed
          @tickets = @tickets.where(:display_user_name => true)
        end
      end

    # specific support tickets
    elsif params[:only]
      case params[:only]
      when "claimed"
        @tickets = @tickets.where("pseud_id is NOT NULL")
      when "admin"
        @tickets = @tickets.where(:admin => true)
      when "comment"
        @tickets = @tickets.where(:comment => true)
        # render a more friendly index page
        render :comment_index and return
      when "waiting"
        @tickets = @tickets.where("code_ticket_id is NOT NULL")
        # render now, because we add not resolved later
        render :index and return
      when "spam"
        @tickets = @tickets.where(:approved => false)
        # render now, because we add not spam later
        render :index and return
      end

    # default - unowned tickets
    else
      @tickets = @tickets.where(:pseud_id => nil)
    end

    # if we haven't rendered before this, rule out closed tickets and spam
    @tickets = @tickets.where(:resolved => false).where(:approved => true)
  end

  def show
    if params[:authentication_code]
      session[:authentication_code] = params[:authentication_code]
    end
    Rails.logger.debug "show session: #{session}"
    @ticket = SupportTicket.find(params[:id])
    is_owner = @ticket.owner?(session[:authentication_code], current_user) # is viewer owner of ticket?

    if @ticket.private && (!is_owner && !current_user.try(:support_volunteer))
      flash[:error] = "Sorry, you don't have permission to view this ticket"
      redirect_to support_path and return
    end

    if is_owner
      @details = @ticket.support_details.not_private
      @ticket.support_details.build # create a new empty response template
      render :show_owner
    elsif !current_user
      @details = @ticket.support_details.not_private
      render :show_guest
    elsif current_user.support_volunteer
      @ticket.support_details.build # create a new empty response template
      render :show_volunteer
    else # logged in as non-support volunteer
      if !@ticket.pseud_id # if support took it, it's not longer open for comment
        @ticket.support_details.build # create a new empty response template
      end
      render :show_user
    end
  end

  def new
    @ticket = SupportTicket.new
    @ticket.support_details.build
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

    # boolean toggles for support volunteers
    if current_user.try(:support_volunteer) && params[:commit] != "Update Support ticket"
      pseud = current_user.support_pseud
      case params[:commit]
      when "Take"
        @ticket.send_steal_notification(pseud) if @ticket.pseud_id
        @ticket.update_attribute(:pseud_id, pseud.id)
      when "Untake"
        @ticket.update_attribute(:pseud_id, nil)
      when "Ham"
        @ticket.mark_as_ham!
      when "Spam"
        @ticket.mark_as_spam!
      when "Comment"
        @ticket.mark_as_comment!(pseud)
      when "Needs Attention"
        @ticket.mark_as_ticket!(pseud)
      when "Needs Admin Attention"
        @ticket.update_attribute(:admin, true)
      when "Remove Code ticket link"
        @ticket.update_attribute(:code_ticket_id, nil)
        @ticket.update_attribute(:pseud_id, pseud.id)
      when "Link to Code ticket"
        @ticket.update_attribute(:code_ticket_id, params[:support_ticket][:code_ticket_id])
        @ticket.update_attribute(:pseud_id, pseud.id)
        @ticket.send_update_notifications
      end
      redirect_to @ticket and return
    end

    # this, and the corresponding hidden field in show_owner.html shouldn't be needed
    # but capybara is loosing the session information for some reason when posting
    Rails.logger.debug "update session: #{session}"
    if params[:authentication_code]
      session[:authentication_code] = params[:authentication_code]
    end
    Rails.logger.debug "update fixed session: #{session}"

    # at the moment we're relying on the displayed form to limit the fields
    # FIXME only allow update_attributes for the submitter's authorization
    # to prevent malicious changes from people not using the web form
    @ticket.update_attributes(params[:support_ticket])
    if @ticket.save
      flash[:notice] = "Support ticket updated"
      @ticket.update_watchers(current_user)
      @ticket.send_update_notifications
      redirect_to @ticket
    else
      flash[:error] = @ticket.errors.full_messages.join(", ")
      render :edit
    end
  end

end
