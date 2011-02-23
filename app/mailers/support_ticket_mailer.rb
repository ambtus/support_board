class SupportTicketMailer < ActionMailer::Base
  default :from => "do-not-reply@ao3.org"

  def create_notification(ticket, recipient)
    @ticket = ticket
    if @ticket.authentication_code && recipient == ticket.email
      @url = support_ticket_url(@ticket, :authentication_code => @ticket.authentication_code)
    else
      @url = support_ticket_url(@ticket)
    end
    mail(
      :to => recipient,
      :subject => "[AO3] New #{ticket.name}"
    )
  end

  def update_notification(ticket, recipient)
    @ticket = ticket
    if ticket.guest_ticket? && recipient == ticket.email
      @url = support_ticket_url(@ticket, :authentication_code => @ticket.authentication_code)
    else
      @url = support_ticket_url(@ticket)
    end
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

  def steal_notification(ticket, stealer)
    @ticket = ticket
    @stealer = stealer
    mail(
      :to => @ticket.support_identity.user.email,
      :subject => "[AO3] Stolen #{ticket.name}"
    )
  end

  def request_to_take(ticket, user, requestor)
    @ticket = ticket
    @requestor = requestor
    @user = user
    mail(
      :to => user.email,
      :subject => "[AO3] Please take #{ticket.name}"
    )
  end

end
