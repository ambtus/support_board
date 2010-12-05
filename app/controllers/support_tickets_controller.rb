class SupportTicketsController < ApplicationController

  def index
    @tickets = SupportTicket.open
    owner = params[:user_id] ? User.find_by_login(params[:user_id]) : false

    # if not support volunteer, and not looking at list of own tickets, can only view public tickets
    if !current_user.try(:is_support_volunteer?) && current_user != owner
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
        @tickets = SupportDetail.where(:pseud_id => owner.pseud_ids).includes(:support_ticket).map(&:support_ticket).uniq

      # tickets I am watching, private
      elsif params[:watching]
        if current_user != owner
          flash[:error] = "Sorry, you don't have permission"
          redirect_back_or_default
        else
          @tickets = SupportWatcher.where(:email => owner.email).includes(:support_ticket).map(&:support_ticket).uniq
        end

      # tickets I opened
      else
        @tickets = @tickets.where(:user_id => owner.id)
        if current_user != owner
          # if not owner, can only see tickets where name is displayed
          @tickets = @tickets.where(:display_user_name => true)
        end
      end

    # claimed support tickets
    elsif params[:claimed]
      @tickets = @tickets.where("pseud_id is NOT NULL")

    # default - unowned tickets
    else
      @tickets = @tickets.where(:pseud_id => nil)
    end
  end

  def show
    if params[:authentication_code]
      session[:authentication_code] = params[:authentication_code]
    end
    Rails.logger.debug "show session: #{session}"
    @ticket = SupportTicket.find(params[:id])
    is_owner = @ticket.owner?(session[:authentication_code], current_user) # is viewer owner of ticket?

    if @ticket.private && (!is_owner && !current_user.try(:is_support_volunteer?))
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
    elsif current_user.is_support_volunteer?
      @ticket.support_details.build # create a new empty response template
      render :show_volunteer
    else # logged in as non-support volunteer
      if !@ticket.pseud_id # not currently being worked by support
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
    # this, and the hidden field in show_owner.html shouldn't be necessary
    # but capybara is loosing the session information for some reason on post
    if params[:authentication_code]
      session[:authentication_code] = params[:authentication_code]
    end
    Rails.logger.debug "update session: #{session}"
    @ticket = SupportTicket.find(params[:id])
    if params[:commit] == "Take"
      if @ticket.pseud_id
        @ticket.send_steal_notification(current_user.support_pseud)
      end
      @ticket.update_attribute(:pseud_id, current_user.support_pseud.id)
      redirect_to @ticket and return
    elsif params[:commit] == "Untake"
      @ticket.update_attribute(:pseud_id, nil)
      redirect_to @ticket and return
    end
    # FIXME check authorization to update ticket
    @ticket.update_attributes(params[:support_ticket])
    if @ticket.save
    Rails.logger.debug "saved here"
      flash[:notice] = "Support ticket updated"
      @ticket.update_watchers(current_user)
      @ticket.send_update_notifications
      redirect_to @ticket
    else
      render :edit
    end
  end

end
