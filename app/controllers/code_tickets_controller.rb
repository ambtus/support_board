class CodeTicketsController < ApplicationController
  def index
    @tickets = CodeTicket.all
  end
  def show
    @ticket = CodeTicket.find(params[:id])
    if !current_user
      render :show_guest
    elsif current_user.is_support_volunteer?
      @ticket.code_details.build # create a new empty response template
      render :show_volunteer
    else # logged in
      render :show_user
    end
  end
end
