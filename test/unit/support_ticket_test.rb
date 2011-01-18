require 'test_helper'

class SupportTicketTest < ActiveSupport::TestCase
  test "create guest ticket with validations" do
    assert_raise(ActiveRecord::RecordInvalid) { SupportTicket.create! }
    assert_raise(ActiveRecord::RecordInvalid) { SupportTicket.create!(:summary => "something short") }
    assert_raise(ActiveRecord::RecordInvalid) { SupportTicket.create!(:summary => "something short",
                                                                      :email => "an invalid address") }
    assert_raise(ActiveRecord::RecordInvalid) { SupportTicket.create!(:summary => SecureRandom.hex(141),
                                                                      :email => "guest@ao3.org") }
    assert ticket = SupportTicket.create!(:summary => "something short", :email => "guest@ao3.org")
    assert_nil ticket.user
    assert ticket.authentication_code
    assert_equal "guest@ao3.org", ticket.email
    assert_equal "something short", ticket.summary
  end
  test "create user ticket with validations" do
    User.current_user = User.first
    assert_raise(ActiveRecord::RecordInvalid) { SupportTicket.create! }
    assert_raise(ActiveRecord::RecordInvalid) { SupportTicket.create!(:summary => SecureRandom.hex(141)) }
    assert ticket = SupportTicket.create!(:summary => "something short")
    assert_equal User.first, ticket.user
    assert_nil ticket.email
    assert_nil ticket.authentication_code
    assert_equal "something short", ticket.summary
  end
  test "if try to create a guest ticket when logged in, get a user ticket" do
    User.current_user = User.first
    assert ticket = SupportTicket.create!(:summary => "something short", :email => "guest@ao3.org")
    assert_equal User.first, ticket.user
    assert_nil ticket.email
    assert_nil ticket.authentication_code
  end
  test "browser string" do
    assert_equal "Chrome 10.0.638.0 (Windows 7)", SupportTicket.first.browser_string
    assert_equal "Internet Explorer 8.0 (Windows XP)", SupportTicket.find(3).browser_string
    assert_equal "Safari 5.0.3 (OS X)", SupportTicket.find(4).browser_string
    assert_equal "Firefox 3.6.13 (OS X)", SupportTicket.find(6).browser_string
    assert_equal "BlackBerry  (BlackBerryOS)", SupportTicket.find(12).browser_string
  end
  test "name" do
    assert_equal "Support Ticket #1", SupportTicket.find(1).name
  end
  test "parens" do
    assert_equal "(a guest)", SupportTicket.first.parens
    assert_equal "(a guest [Private])", SupportTicket.find(2).parens
    assert_equal "(a user)", SupportTicket.find(7).parens
    assert_equal "(a user [Private])", SupportTicket.find(4).parens
    assert_equal "(dean)", SupportTicket.find(3).parens
    assert_equal "(john [Private])", SupportTicket.find(5).parens
  end
  test "status lines" do
    assert_equal "open", SupportTicket.find(1).status_line
    assert_equal "waiting for an admin", SupportTicket.find(17).status_line
    assert_equal "spam", SupportTicket.find(2).status_line
    assert_equal "taken by sam", SupportTicket.find(3).status_line
    assert_equal "waiting for a code fix", SupportTicket.find(4).status_line
    assert_equal "answered by FAQ", SupportTicket.find(5).status_line
    assert_equal "answered by FAQ", SupportTicket.find(6).status_line
  end
  test "owned by volunteer" do
    assert_equal "sam", SupportTicket.find(2).support_identity.name
    assert_equal "rodney", SupportTicket.find(4).support_identity.name
  end
  test "scopes" do
    assert_equal 21, SupportTicket.count
    assert_equal [1, 8, 16, 20], SupportTicket.unowned.ids
    assert_equal [3, 9], SupportTicket.taken.ids
    assert_equal [4, 7, 18], SupportTicket.waiting.ids
    assert_equal [17, 21], SupportTicket.waiting_on_admin.ids
    assert_equal [2], SupportTicket.spam.ids
    assert_equal [5, 6, 19], SupportTicket.closed.ids
    assert_equal [10, 11, 12, 13, 14, 15], SupportTicket.posted.ids
  end
  test "reopen by user" do
    reason = "the faq didn't work"
    ticket = SupportTicket.find(5)
    User.current_user = User.find_by_login("john")
    assert ticket.reopen!(reason)
    assert_equal "open", ticket.status_line
    assert_equal %Q{closed -> unowned (#{reason})}, ticket.support_details.last.content
    assert_nil ticket.support_identity_id
  end
  test "reopen by guest" do
    ticket = SupportTicket.find(1)
    User.current_user = User.find_by_login("sam")
    ticket.needs_fix!(1)
    assert_equal "waiting for a code fix", ticket.status_line
    User.current_user = nil
    reason = "that doesn't sound like my problem"
    assert ticket.reload.reopen!(reason, ticket.authentication_code)
    assert_equal "open", ticket.status_line
    assert_equal %Q{waiting -> unowned (#{reason})}, ticket.support_details.last.content
    assert_nil ticket.reload.support_identity_id
  end
  test "ham" do
    ticket = SupportTicket.find(2)
    User.current_user = User.find_by_login("sam")
    assert ticket.ham!
    assert_equal "open", ticket.status_line
    assert_equal %Q{spam -> unowned}, ticket.support_details.last.content
  end
  test "steal" do
    ticket = SupportTicket.find(3)
    User.current_user = User.find_by_login("rodney")
    assert ticket.steal!
    assert_equal "taken by rodney", ticket.reload.status_line
  end
  test "guest owner accepts answer" do
    ticket = SupportTicket.find(1)
    assert_equal "open", ticket.status_line
    assert_equal 0, ticket.support_details.count
    User.current_user = User.find_by_login("dean")
    assert ticket.user_comment!("right answer")
    assert_equal 1, ticket.support_details.count
    detail = ticket.support_details.first
    assert_raise(SecurityError) { ticket.accept!(detail.id) }
    User.current_user = nil
    assert ticket.accept!(detail.id, ticket.authentication_code)
    assert_equal "closed by owner", ticket.status_line
  end
  test "user owner accepts answer" do
    ticket = SupportTicket.find(3)
    assert_equal "taken by sam", ticket.status_line
    assert_equal 2, ticket.support_details.count
    User.current_user = User.find_by_login("rodney")
    assert ticket.user_comment!("right answer")
    assert_equal 3, ticket.support_details.count
    detail = ticket.support_details.last
    assert_raise(SecurityError) { ticket.accept!(detail.id) }
    User.current_user = User.find_by_login("sam")
    assert_raise(SecurityError) { ticket.accept!(detail.id) }
    User.current_user = User.find_by_login("dean")
    assert ticket.accept!(detail.id)
    assert_equal "closed by owner", ticket.status_line
  end
  test "user owner reopens one answered ticket" do
    User.current_user = User.find_by_login("john")
    ticket1 = SupportTicket.find(4)
    ticket2 = SupportTicket.find(5)
    assert ticket1.reopen!("test")
    assert ticket2.reopen!("test")
    assert ticket1.accept!(ticket1.support_details.first.id)
    assert ticket2.accept!(ticket2.support_details.first.id)
    assert "closed by owner", ticket1.status_line
    assert "closed by owner", ticket2.status_line
    assert ticket1.reopen!("test")
    assert "open", ticket1.status_line
    assert "closed by owner", ticket2.status_line
  end
end
