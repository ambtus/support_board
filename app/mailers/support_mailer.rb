class SupportMailer < ActionMailer::Base
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
    @details = (@ticket.support_details.count > 0) ? @ticket.support_details : []
    mail(
      :to => recipient,
      :subject => "[AO3] Updated #{ticket.name}"
    )
  end

  def send_links(email, tickets)
    @tickets = tickets
    mail(
      :to => email,
      :subject => "[AO3] Access links for support tickets"
    )
  end
end
