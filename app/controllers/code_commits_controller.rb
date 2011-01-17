class CodeCommitsController < ApplicationController
  def index
    @commits = CodeCommit.filter(params)
  end
  def show
    @commit = CodeCommit.find params[:id]
  end
  def update
    if !current_user.try(:support_admin?)
      flash[:notice] = "Sorry, only support admins can match commits."
    else
      commit = CodeCommit.find params[:id]
      case params[:commit]
      when "Unmatch"
        commit.unmatch!
      when "Match"
        ticket = CodeTicket.find params[:code_ticket_id]
        commit.match!(ticket)
        redirect_to ticket and return
      end
    end
    redirect_to code_commits_path
  end
end
