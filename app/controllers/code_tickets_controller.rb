class CodeTicketsController < ApplicationController
  def index
    if params[:resolved]
      @tickets = CodeTicket.where(:resolved => true)
    else
      @tickets = CodeTicket.where(:resolved => false)
    end

    # tickets associated with a user
    if params[:user_id]
      user = User.find_by_login(params[:user_id])

      # tickets I voted on, public
      if params[:votes]
        @tickets = CodeVote.where(:user_id => user.id).includes(:code_ticket).map(&:code_ticket).uniq

      # tickets I commented on, public
      elsif params[:comments]
        @tickets = @tickets.joins(:code_details) & CodeDetail.where(:support_identity_id => user.support_identity_id)

      # tickets I am watching, private
      elsif params[:watching]
        if current_user != user
          flash[:error] = "Sorry, you don't have permission"
          redirect_back_or_default
        else
          @tickets = @tickets.joins(:code_notifications) & CodeNotification.where(:email => user.email)
        end

      # support volunteer's working tickets
      elsif params[:support]
        @tickets = @tickets.where(:support_identity_id => user.support_identity_id)
      end

    end
  end

  def show
    @ticket = CodeTicket.find(params[:id])

    if !current_user
      @details = @ticket.code_details.where(:private => false)
      render :show_guest
    elsif current_user.support_volunteer?
      @ticket.code_details.build(:support_response => true) # create a new empty response template
      render :show_volunteer
    else # logged in as non-support volunteer
      if !@ticket.support_identity_id # if support took it, it's not longer open for comment
        @ticket.code_details.build # create a new empty response template
      end
      render :show_user
    end

  end

  def new
    if current_user.support_volunteer?
      @ticket = CodeTicket.new
      @ticket.code_details.build(:support_response => true)
    else
      flash[:notice] = "Sorry, only volunteers can open code tickets. Please open a support ticket instead"
      redirect_to new_support_ticket_path and return
    end
  end

  def create
    if current_user.support_volunteer?
      @ticket = CodeTicket.new(params[:code_ticket])
      if @ticket.save
        flash[:notice] = "Code ticket created"
        if @ticket.authentication_code
          redirect_to code_ticket_path(@ticket, :authentication_code => @ticket.authentication_code)
        else
          redirect_to @ticket
        end
        @ticket.send_create_notifications
      else
        # reset so don't get field with errors which breaks definition lists
        flash[:error] = @ticket.errors.full_messages.join(", ")
        @ticket = CodeTicket.new(params[:code_ticket])
        render :new
      end
    else
      flash[:notice] = "Sorry, only support volunteers can open code tickets. Please open a support ticket instead"
      redirect_to new_support_ticket_path and return
    end
  end

  def edit
    @ticket = CodeTicket.find(params[:id])
    if current_user.support_volunteer?
      @ticket.code_details.build(:support_response => true) # create a new empty response template
    else
      flash[:notice] = "Sorry, only support volunteers can edit code tickets"
      redirect_to @ticket and return
    end
  end

  def update
    @ticket = CodeTicket.find(params[:id])
    @ticket.update_attributes(params[:code_ticket])
    if current_user.try(:support_volunteer?) && params[:commit] != "Update Code ticket"
      support_identity = current_user.support_identity
      case params[:commit]
      when "Take"
        @ticket.update_attribute(:support_identity_id, current_user.support_identity_id)
      when "Dupe"
        @ticket.update_attribute(:support_identity_id, current_user.support_identity_id)
      end
      redirect_to @ticket and return
    elsif current_user
      @ticket.update_attributes(params[:code_ticket])
      if @ticket.save
        flash[:notice] = "Code ticket updated"
        @ticket.update_votes(current_user)
        @ticket.update_watchers(current_user)
        @ticket.send_update_notifications
        if !current_user && @ticket.authentication_code
          redirect_to code_ticket_path(@ticket, :authentication_code => @ticket.authentication_code)
        else
          redirect_to @ticket
        end
      else
        render :edit
      end
    else
      flash[:notice] = "Sorry, you don't have permission"
      redirect_back_or_default(@ticket) and return
    end
  end
end
