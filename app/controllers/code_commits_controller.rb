class CodeCommitsController < ApplicationController
  def index
    case params[:status]
    when "matched"
      @commits = CodeCommit.matched
    when "staged"
      @commits = CodeCommit.staged
    when "verified"
      @commits = CodeCommit.verified
    else
      @commits = CodeCommit.unmatched
    end
  end
  def show
    @commit = CodeCommit.find params[:id]
  end
  def update
    if !current_user.try(:support_admin?)
      flash[:notice] = "Sorry, only support admins can match commits."
    else
      ticket = CodeTicket.find params[:code_ticket_id]
      ticket.commit!(params[:id])
    end
    redirect_to code_commits_path
  end
end
