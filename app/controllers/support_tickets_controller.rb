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
      @tickets = @tickets.where(:pseud_id => params[:pseud_id])

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

    # front page - only show unowned tickets
    else
      @tickets = @tickets.where(:pseud_id => nil)
    end
  end

  def show
    @ticket = SupportTicket.find(params[:id])
    is_owner = @ticket.owner?(params[:authentication_code], current_user) # is viewer owner of ticket?

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
      @details = @ticket.support_details
      @ticket.support_details.build # create a new empty response template
      render :show_volunteer
    else # logged in as non-support volunteer
      @details = @ticket.support_details.not_private
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
        SupportMailer.send_links(params[:email], @tickets).deliver
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
        redirect_to support_ticket_path(@ticket, :authentication_code => @ticket.authentication_code)
      else
        redirect_to @ticket
      end
      @ticket.send_create_notifications
    else
      # reset so don't get field with errors which breaks definition lists
      flash[:error] = @ticket.errors.full_messages.join(", ")
      @ticket = SupportTicket.new(params[:support_ticket])
      render :new
    end
  end

  def update
    # FIXME check authorization to update ticket
    @ticket = SupportTicket.find(params[:id])
    if params[:commit] == "Take"
      @ticket.update_attribute(:pseud_id, current_user.support_pseud.id)
      redirect_to @ticket and return
    end
    @ticket.update_attributes(params[:support_ticket])
    if @ticket.save
    Rails.logger.debug "saved here"
      flash[:notice] = "Support ticket updated"
      @ticket.update_watchers(current_user)
      @ticket.send_update_notifications
      if !current_user && @ticket.authentication_code
        redirect_to support_ticket_path(@ticket, :authentication_code => @ticket.authentication_code)
      else
        redirect_to @ticket
      end
    else
      render :edit
    end
  end
end
