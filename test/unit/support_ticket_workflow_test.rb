require 'test_helper'

# workflow and related methods
class SupportTicketTest < ActiveSupport::TestCase
  test "scopes" do
    assert_equal 22, SupportTicket.count
    assert_equal [1, 8, 16, 20], SupportTicket.unowned.ids
    assert_equal [3, 9], SupportTicket.taken.ids
    assert_equal [4, 7], SupportTicket.waiting.ids
    assert_equal [17, 21], SupportTicket.waiting_on_admin.ids
    assert_equal [2], SupportTicket.spam.ids
    assert_equal [5, 6, 18, 19, 22], SupportTicket.closed.ids
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
