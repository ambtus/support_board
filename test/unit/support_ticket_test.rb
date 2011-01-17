require 'test_helper'

class SupportTicketTest < ActiveSupport::TestCase
  test "name" do
    assert_equal "Support Ticket #1", SupportTicket.find(1).name
  end
  test "status lines" do
    assert_equal "open", SupportTicket.find(1).status_line
    two = SupportTicket.find(2)
    assert_equal "spam", two.status_line
    assert_equal %Q{unowned -> spam}, two.support_details.system_log.last.content
    assert_equal "sam", two.support_identity.name
    three = SupportTicket.find(3)
    assert_equal "taken by sam", three.status_line
    assert_equal %Q{unowned -> taken}, three.support_details.system_log.last.content
    four = SupportTicket.find(4)
    assert_equal "waiting for a code fix", four.status_line
    assert_equal %Q{unowned -> waiting (3)}, four.support_details.system_log.last.content
    assert_equal "rodney", four.support_identity.name
    five = SupportTicket.find(5)
    assert_equal "closed by rodney", five.status_line
    assert_equal %Q{unowned -> closed (4)}, five.support_details.system_log.last.content
    six = SupportTicket.find(6)
    assert_equal "closed by blair", six.status_line
    assert_equal %Q{unowned -> closed (5)}, six.support_details.system_log.last.content
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
    User.current_user = nil
    assert_equal "waiting for a code fix", ticket.status_line
    reason = "that doesn't sound like my problem"
    assert ticket.reload.reopen!(reason, "guest@ao3.org")
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
  test "watch guest ticket" do
    ticket = SupportTicket.find(1)
    assert_equal 1, ticket.mail_to.size
    User.current_user = nil
    assert_raise(SecurityError) { ticket.watch! }
    assert_equal 1, ticket.mail_to.size
    assert ticket.unwatch!("guest@ao3.org")
    assert_equal 0, ticket.reload.mail_to.size
    assert !ticket.watched?("guest@ao3.org")
    assert_raise(SecurityError) { ticket.watch!("someone@ao3.org") }
    User.current_user = User.find_by_login("dean")
    assert_nil ticket.watched?
    assert_raise(RuntimeError) { ticket.unwatch! }
    assert ticket.watch!
    assert_raise(RuntimeError) { ticket.watch! }
    assert_equal 1, ticket.mail_to.size
    User.current_user = User.find_by_login("john")
    assert_nil ticket.watched?
    assert ticket.watch!
    assert_equal 2, ticket.mail_to.size
    assert ticket.unwatch!
    assert_equal 1, ticket.reload.mail_to.size
    assert_nil ticket.watched?
    assert ticket.watch!("guest@ao3.org")
    assert_equal 2, ticket.mail_to.size
    assert ticket.make_private!("guest@ao3.org")
    assert_equal 1, ticket.reload.mail_to.size
    assert_equal "made private", ticket.support_details.last.content
    User.current_user = User.find_by_login("john")
    assert_nil ticket.watched?
    assert_raise(SecurityError) { ticket.watch! }
    User.current_user = User.find_by_login("sam")
    assert_nil ticket.watched?
    assert ticket.watch!
    assert_equal 2, ticket.mail_to.size
  end
  test "watch user ticket" do
    ticket = SupportTicket.find(3)
    User.current_user = User.find_by_login("sam")
    assert ticket.watched?
    assert_equal 2, ticket.mail_to.size
    User.current_user = nil
    assert_raise(SecurityError) { ticket.watch! }
    assert_raise(SecurityError) { ticket.watch!("guest@ao3.org") }
    assert_equal 2, ticket.mail_to.size
    User.current_user = User.find_by_login("dean")
    assert ticket.watched?
    assert_raise(RuntimeError) { ticket.watch! }
    assert_equal 2, ticket.mail_to.size
    User.current_user = User.find_by_login("john")
    assert_nil ticket.watched?
    assert ticket.watch!
    assert_equal 3, ticket.mail_to.size
    assert ticket.watched?
    User.current_user = User.find_by_login("dean")
    assert ticket.make_private!
    assert_equal 2, ticket.reload.mail_to.size
    assert_equal "made private", ticket.support_details.last.content
    User.current_user = User.find_by_login("john")
    assert_nil ticket.watched?
    assert_raise(SecurityError) { ticket.watch! }
  end
  test "guest owner accepts answer" do
    ticket = SupportTicket.find(1)
    assert_equal "open", ticket.status_line
    assert_equal 0, ticket.support_details.count
    User.current_user = User.find_by_login("dean")
    assert ticket.comment!("right answer")
    assert_equal 1, ticket.support_details.count
    detail = ticket.support_details.first
    assert_raise(SecurityError) { ticket.accept!(detail.id) }
    assert ticket.accept!(detail.id, "guest@ao3.org")
    assert_equal "closed by owner", ticket.status_line
  end
  test "user owner accepts answer" do
    ticket = SupportTicket.find(3)
    assert_equal "taken by sam", ticket.status_line
    assert_equal 2, ticket.support_details.count
    User.current_user = User.find_by_login("rodney")
    assert ticket.comment!("right answer")
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
