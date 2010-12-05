class SupportTicketMailer < ActionMailer::Base
  default :from => "do-not-reply@ao3.org"

  def create_notification(ticket, recipient)
    @ticket = ticket
    if @ticket.authentication_code
      @url = support_ticket_path(@ticket, :only_path => false, :authentication_code => @ticket.authentication_code)
    else
      @url = support_ticket_path(@ticket, :only_path => false)
    end
    @detail = @ticket.support_details.first
    mail(
      :to => recipient,
      :subject => "[AO3] New #{ticket.name}"
    )
  end

  def update_notification(ticket, recipient)
    @ticket = ticket
    if @ticket.authentication_code
      @url = support_ticket_path(@ticket, :only_path => false, :authentication_code => @ticket.authentication_code)
    else
      @url = support_ticket_path(@ticket, :only_path => false)
    end
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

  def steal_notification(ticket, stealer)
    @ticket = ticket
    @stealer = stealer
    @url = support_ticket_path(@ticket, :only_path => false)
    @details = (@ticket.support_details.count > 0) ? @ticket.support_details : []
    mail(
      :to => @ticket.pseud.user.email,
      :subject => "[AO3] Stolen #{ticket.name}"
    )
  end

end
