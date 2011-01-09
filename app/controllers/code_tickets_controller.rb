class CodeTicketsController < ApplicationController
  def index
    if params[:status]
      @tickets = CodeTicket.send(params[:status])
    else
      @tickets = CodeTicket.not_closed
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
      else
        @tickets = @tickets.where(:support_identity_id => user.support_identity_id)
      end

    end
    @tickets = @tickets.sort_by_vote if params[:by_vote]
  end

  def show
    @ticket = CodeTicket.find(params[:id])

    if !current_user
      @details = @ticket.code_details.where(:private => false)
      render :show_guest
    elsif current_user.support_volunteer?
      @add_details = true # create a new empty response template
      render :show_volunteer
    else # logged in as non-support volunteer
      if !@ticket.support_identity_id # if support took it, it's not longer open for comment
        @add_details = true # create a new empty response template
      end
      render :show_user
    end

  end

  def new
    if !current_user.try(:support_volunteer?)
      flash[:notice] = "Sorry, only support volunteers can open code tickets. Please open a support ticket instead"
      redirect_to new_support_ticket_path and return
    end
    @ticket = CodeTicket.new
    @add_details = true # create a new empty response template
  end

  def create
    if !current_user.try(:support_volunteer?)
      flash[:notice] = "Sorry, only support volunteers can open code tickets. Please open a support ticket instead"
      redirect_to new_support_ticket_path and return
    end
    case params[:commit]
    when "Stage Committed Code Tickets"
      CodeTicket.stage!(params[:stage_revision])
      redirect_to support_path and return
    when "Deploy Verified Code Tickets"
      CodeTicket.deploy!
      redirect_to support_path and return
    else
      @ticket = CodeTicket.new(params[:code_ticket])
      if @ticket.save
        flash[:notice] = "Code ticket created"
        redirect_to @ticket
        @ticket.send_create_notifications
      else
        # reset so don't get field with errors which breaks definition lists
        flash[:error] = @ticket.errors.full_messages.join(", ")
        @ticket = CodeTicket.new(params[:code_ticket])
        render :new
      end
    end
  end

  def edit
    @ticket = CodeTicket.find(params[:id])
  end

  def update
    @ticket = CodeTicket.find(params[:id])
    case params[:commit]
    when "Take"
      @ticket.take!
    when "Steal"
      @ticket.steal!
    when "Dupe"
      @ticket.duplicate!(params[:code_ticket_id])
    when "Reopen"
      @ticket.reopen!(params[:reason])
    when "Reject"
      @ticket.reject!(params[:reason])
    when "Verify"
      @ticket.verify!(SupportBoard::REVISION_NUMBER)
    when "Vote for this ticket"
      @ticket.vote!
    when "Watch this ticket"
      @ticket.watch!
    when "Don't watch this ticket"
      @ticket.unwatch!
    when "Add details"
      @ticket.comment!(params[:content], !params[:unofficial])
    when "Update Code ticket"
      @ticket.update_from_edit!(params[:code_ticket][:summary],
                      params[:code_ticket][:description],
                      params[:code_ticket][:url],
                      params[:code_ticket][:browser])
    end
    redirect_to @ticket
  end
end
