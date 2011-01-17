class FaqMailer < ActionMailer::Base
  default :from => "do-not-reply@ao3.org"

  def update_notification(faq, recipient)
    @faq = ticket
    @details = (@faq.faq_details.count > 0) ? @faq.code_details : []
    mail(
      :to => recipient,
      :subject => "[AO3] Updated FAQ #{faq.summary}"
    )
  end

end
