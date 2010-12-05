class CodeTicketMailer < ActionMailer::Base
  default :from => "do-not-reply@ao3.org"

  def create_notification(ticket, recipient)
    @ticket = ticket
    @detail = @ticket.code_details.first
    mail(
      :to => recipient,
      :subject => "[AO3] New #{ticket.name}"
    )
  end

  def update_notification(ticket, recipient)
    @ticket = ticket
    @details = (@ticket.code_details.count > 0) ? @ticket.code_details : []
    mail(
      :to => recipient,
      :subject => "[AO3] Updated #{ticket.name}"
    )
  end

end