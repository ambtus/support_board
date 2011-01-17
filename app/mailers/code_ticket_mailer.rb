class CodeTicketMailer < ActionMailer::Base
  default :from => "do-not-reply@ao3.org"

  def create_notification(ticket, recipient)
    @ticket = ticket
    mail(
      :to => recipient,
      :subject => "[AO3] New #{ticket.name}"
    )
  end

  def update_notification(ticket, recipient)
    @ticket = ticket
    mail(
      :to => recipient,
      :subject => "[AO3] Updated #{ticket.name}"
    )
  end

  def steal_notification(ticket, stealer)
    @ticket = ticket
    @stealer = stealer
    @url = code_ticket_url(@ticket)
    mail(
      :to => @ticket.support_identity.user.email,
      :subject => "[AO3] Stolen #{ticket.name}"
    )
  end

end
