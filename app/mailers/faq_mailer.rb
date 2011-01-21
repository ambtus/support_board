class FaqMailer < ActionMailer::Base
  default :from => "do-not-reply@ao3.org"

  def update_notification(faq, recipient)
    @faq = faq
    mail(
      :to => recipient,
      :subject => "[AO3] Updated FAQ #{faq.sanitized_summary}"
    )
  end

end
