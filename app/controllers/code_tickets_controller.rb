class CodeTicketsController < ApplicationController
  def index
    begin
      @tickets = CodeTicket.filter(params)
    rescue SecurityError
      flash[:error] = "Please log in"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Please check your spelling"
    end
    unless @tickets
      @tickets = []
    end
  end

  def show
    @ticket = CodeTicket.find(params[:id])
    @details = @ticket.visible_code_details

    if !current_user
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
      flash[:error] = "Sorry, only support volunteers can open code tickets. Please open a support ticket instead"
      redirect_to new_support_ticket_path and return
    end
    @ticket = CodeTicket.new
    @add_details = true # create a new empty response template
  end

  def create
    if !current_user.try(:support_volunteer?)
      flash[:error] = "Sorry, only support volunteers can create code tickets. Please open a support ticket instead"
      redirect_to new_support_ticket_path and return
    end
    case params[:commit]
    when "Stage Committed Code Tickets"
      CodeTicket.stage!
      redirect_to code_tickets_path(:status => "staged") and return
    when "Deploy Verified Code Tickets"
      note = CodeTicket.deploy!(params[:release_note])
      redirect_to note and return
    else
      @ticket = CodeTicket.new(params[:code_ticket])
      if @ticket.save
        flash[:notice] = "Code ticket created"
        @ticket.comment!(params[:details])
        redirect_to @ticket
      else
        # reset so don't get field with errors which breaks definition lists
        flash[:error] = @ticket.errors.full_messages.join(", ")
        @ticket = CodeTicket.new(params[:code_ticket])
        render :new
      end
    end
  end

  def edit
    if !current_user.try(:support_volunteer?)
      flash[:error] = "Sorry, only support volunteers can edit code tickets."
      redirect_to new_support_ticket_path and return
    end
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
    when "Commit"
      @ticket.commit!(params[:code_commit_id])
    when "Reopen"
      @ticket.reopen!(params[:reason])
    when "Reject"
      @ticket.reject!(params[:reason])
    when "Verify"
      @ticket.verify!
    when "Vote up"
      @ticket.vote!
    when "Watch this ticket"
      @ticket.watch!
    when "Don't watch this ticket"
      @ticket.unwatch!
    when "Add details"
      @ticket.comment!(params[:content], params[:response])
    when "Update Code ticket"
      @ticket.update_from_edit!(params[:code_ticket][:summary],
                      params[:code_ticket][:url],
                      params[:code_ticket][:browser])
    end
    redirect_to @ticket
  end
end
