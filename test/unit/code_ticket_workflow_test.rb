require 'test_helper'

class CodeTicketWorkflowTest < ActiveSupport::TestCase
  test "reopen" do
    reason = "sorry, I don't have time to save the world this month"
    ticket = CodeTicket.find(2)
    User.current_user = User.find_by_login("sam")
    assert ticket.reopen!(reason)
    assert_equal "open", ticket.status_line
    assert_equal %Q{taken -> unowned (#{reason})}, ticket.code_details.last.content
    assert_nil ticket.support_identity_id
  end
  test "reject" do
    reason = "not reproducible"
    ticket = CodeTicket.find(1)
    User.current_user = User.find_by_login("sam")
    assert_raise(RuntimeError) { ticket.reject!(reason) }
    User.current_user = User.find_by_login("rodney")
    assert ticket.reject!(reason)
    assert_equal "closed by rodney", ticket.status_line
    assert_equal %Q{unowned -> closed (#{reason})}, ticket.code_details.last.content
  end
  test "steal" do
    ticket = CodeTicket.find(2)
    User.current_user = User.find_by_login("rodney")
    assert ticket.steal!
    assert_equal "taken by rodney", ticket.reload.status_line
  end
  test "duplicate" do
    ticket = CodeTicket.find(1)
    dupe = CodeTicket.find(2)
    User.current_user = User.find_by_login("rodney")
    assert dupe.duplicate!(ticket.id)
    assert_equal "closed as duplicate by rodney", dupe.status_line
    assert_equal ticket.id, dupe.code_ticket_id
    assert dupe.reopen!("different bug")
    assert_nil dupe.code_ticket_id
    assert_equal "open", ticket.status_line
  end
  test "move watchers from duplicate" do
    ticket = CodeTicket.find(1)
    assert_equal 0, ticket.mail_to.size
    dupe = CodeTicket.find(2)
    assert_equal 1, dupe.mail_to.size # sam
    User.current_user = User.find_by_login("john")
    dupe.watch!
    assert_equal 2, dupe.mail_to.size # sam and john
    User.current_user = User.find_by_login("rodney")
    assert dupe.duplicate!(ticket.id)
    assert_equal 2, ticket.reload.mail_to.size
    assert_equal 0, dupe.reload.mail_to.size
  end
  test "move votes from duplicate" do
    ticket = CodeTicket.find(1)
    assert_equal 1, ticket.vote_count
    dupe = CodeTicket.find(2)
    assert_equal 4, dupe.vote_count
    User.current_user = User.find_by_login("rodney")
    assert dupe.duplicate!(ticket.id)
    assert_equal 5, ticket.vote_count
    assert_equal 0, dupe.vote_count
  end
  test "move support tickets from duplicate" do
    ticket = CodeTicket.find(1)
    assert_equal 0, ticket.support_tickets.count
    dupe = CodeTicket.find(5)
    assert_equal 1, dupe.support_tickets.count
    User.current_user = User.find_by_login("rodney")
    assert dupe.duplicate!(ticket.id)
    assert_equal 1, ticket.support_tickets.count
    assert_equal 0, dupe.support_tickets.count
  end
  test "scopes" do
    assert_equal 7, CodeTicket.all.count
    assert_equal 5, CodeTicket.not_closed.count
    assert_equal [1], CodeTicket.unowned.ids
    assert_equal [2], CodeTicket.taken.ids
    assert_equal [5], CodeTicket.committed.ids
    assert_equal [4], CodeTicket.staged.ids
    assert_equal [3], CodeTicket.verified.ids
    assert_equal [6, 7], CodeTicket.closed.ids
  end
end
