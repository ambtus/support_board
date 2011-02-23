require 'test_helper'

class FaqTest < ActiveSupport::TestCase
  test "default scope by position" do
    assert_equal [1, 2, 3, 4, 5], Faq.select("faqs.id").map(&:id)
    Faq.find(3).update_attribute(:position, 6)
    assert_equal [1, 2, 4, 5, 3], Faq.select("faqs.id").map(&:id)
    Faq.find(1).update_attribute(:position, 3)
    assert_equal [2, 1, 4, 5, 3], Faq.select("faqs.id").map(&:id)
  end
  test "create with validations and callbacks" do
    assert_raise(SecurityError) { Faq.create!(:summary => "short summary", :content  => "something") }
    User.current_user = User.find_by_login("jim")
    assert_raise(SecurityError) { Faq.create!(:summary => "short summary", :content  => "something") }
    User.current_user = User.find_by_login("sam")
    assert_raise(ActiveRecord::RecordInvalid) { Faq.create! }
    assert_raise(ActiveRecord::RecordInvalid) { Faq.create!(:summary => "short summary", :content => "")}
    assert_raise(ActiveRecord::RecordInvalid) { Faq.create!(:summary => SecureRandom.hex(141), :content => "something")}
    assert faq = Faq.create(:summary => "short summary", :content => "something")
    assert_equal 6, faq.position
    assert_equal ["sam@ao3.org"], faq.mail_to
  end
  test "create without notification" do
    User.current_user = User.find_by_login("sam")
    assert faq = Faq.create(:summary => "short summary", :content => "something", :turn_off_notifications => "1")
    assert_equal [], faq.mail_to
  end
  test "normal flow" do
    assert_equal "rfc", Faq.find(2).status
    assert_equal "faq", Faq.find(1).status
  end
  test "reopen" do
    reason = "there seems to be some confusion about this"
    faq = Faq.find(1)
    sam = User.find_by_login("sam")
    User.current_user = sam
    assert faq.open_for_comments!(reason)
    assert_equal "rfc", faq.status
    assert_equal %Q{faq -> rfc (#{reason})}, faq.faq_details.last.content
  end
  test "post" do
    faq = Faq.find(2)
    User.current_user = User.find_by_login("sam")
    assert_equal false, User.current_user.support_admin?
    assert_raise(SecurityError) { faq.post! }
    sidra = User.find_by_login("sidra")
    User.current_user = sidra
    assert faq.post!
    assert_equal "faq", faq.status
    assert_equal %Q{rfc -> faq}, faq.faq_details.last.content
  end
  test "scopes" do
    assert_equal 3, Faq.faq.count
    assert_equal 2, Faq.rfc.count
  end
  test "vote" do
    faq = Faq.find(1)
    assert faq.faq?
    User.current_user = nil
    assert faq.vote!
    assert_equal 1, faq.vote_count
    User.current_user = User.find_by_login("dean")
    assert faq.vote!
    assert faq.vote!
    assert_equal 3, faq.vote_count
    User.current_user = User.find_by_login("john")
    assert faq.vote!
    assert_equal 4, faq.vote_count
  end
  test "vote on draft" do
    faq = Faq.find(2)
    assert faq.rfc?
    User.current_user = nil
    assert_raise(RuntimeError) { faq.vote! }
    User.current_user = User.find_by_login("dean")
    assert_raise(RuntimeError) { faq.vote! }
    User.current_user = User.find_by_login("sam")
    assert_raise(RuntimeError) { faq.vote! }
  end
  test "votes when adding a ticket to a faq" do
    support_ticket = SupportTicket.find(1)
    faq = Faq.find(1)
    assert_equal 0, faq.vote_count
    User.current_user = User.find_by_login("sam")
    assert support_ticket.answer!(faq.id)
    assert_equal 2, faq.vote_count
  end
  test "watch" do
    faq = Faq.find(1)
    User.current_user = nil
    assert_raise(SecurityError) { faq.watch! }
    assert_equal 1, faq.mail_to.size
    User.current_user = User.find_by_login("dean")
    assert_raise(RuntimeError) { faq.unwatch! }
    assert faq.watch!
    assert_equal 2, faq.mail_to.size
    assert faq.watch!
    assert_equal 2, faq.mail_to.size
    User.current_user = User.find_by_login("john")
    assert_nil faq.watched?
    assert faq.watch!
    assert_equal 3, faq.mail_to.size
    assert faq.unwatch!
    assert_equal 2, faq.reload.mail_to.size
    assert_nil faq.watched?
  end
  test "watch by guest" do
    support_ticket = SupportTicket.find(1)
    faq = Faq.find(1)
    assert_equal ["sam@ao3.org"], faq.mail_to
    User.current_user = User.find_by_login("sam")
    assert support_ticket.answer!(faq.id)
    User.current_user = nil
    assert_raise(SecurityError) { faq.watch!("randomstring") }
    assert faq.watch!(support_ticket.authentication_code)
    assert_equal ["sam@ao3.org", "guest@ao3.org"], faq.mail_to
    assert faq.watched?(support_ticket.authentication_code)
    assert_raise(SecurityError) { faq.unwatch!("randomstring") }
    assert faq.unwatch!(support_ticket.authentication_code)
    assert_nil faq.watched?(support_ticket.authentication_code)
    assert_equal ["sam@ao3.org"], faq.reload.mail_to
  end
  test "watch by guest of an unrelated faq" do
    support_ticket = SupportTicket.find(1)
    faq = Faq.find(3)
    assert_equal ["rodney@ao3.org"], faq.mail_to
    User.current_user = User.find_by_login("sam")
    assert support_ticket.answer!(faq.id)
    User.current_user = nil
    assert faq.watch!(support_ticket.authentication_code)
    assert_equal ["rodney@ao3.org", "guest@ao3.org"], faq.mail_to
    assert faq.watched?(support_ticket.authentication_code)
    assert faq.unwatch!(support_ticket.authentication_code)
    assert_nil faq.watched?(support_ticket.authentication_code)
    assert_equal ["rodney@ao3.org"], faq.reload.mail_to
  end
  test "can comment on a faq when it's in rfc mode" do
    faq = Faq.find(2)
    assert faq.rfc?
    assert_equal 2, faq.faq_details.count
    User.current_user = nil
    assert_raise(SecurityError) { faq.comment!("something") }
    assert_equal 2, faq.faq_details.count
    User.current_user = User.find_by_login("dean")
    assert detail = faq.comment!("user")
    assert_equal 3, faq.faq_details.count
    assert_equal "user", detail.content
    assert_match "dean wrote", detail.info
    User.current_user = User.find_by_login("sam")
    assert detail = faq.comment!("volunteer")
    assert_equal 4, faq.faq_details.count
    assert_equal "volunteer", detail.content
    assert_match "sam (volunteer) wrote", detail.info
    assert detail = faq.comment!("unofficial volunteer", false)
    assert_equal 5, faq.faq_details.count
    assert_equal "unofficial volunteer", detail.content
    assert_match "sam wrote", detail.info
  end
  test "can't comment on faq after it's posted" do
    faq = Faq.find(1)
    User.current_user = User.find_by_login("dean")
    assert_raise(RuntimeError) { faq.comment!("something") }
    User.current_user = User.find_by_login("sam")
    assert_raise(RuntimeError) { faq.comment!("something") }
    User.current_user = User.find_by_login("sidra")
    assert_raise(RuntimeError) { faq.comment!("something") }
  end
end
