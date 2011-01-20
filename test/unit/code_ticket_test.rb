require 'test_helper'

class CodeTicketTest < ActiveSupport::TestCase
  test "name" do
    assert_equal "Code Ticket #1", CodeTicket.find(1).name
  end
  test "normal flow" do
    assert_equal "open", CodeTicket.find(1).status_line
    two = CodeTicket.find(2)
    assert_equal "taken by sam", two.status_line
    assert_equal %Q{unowned -> taken}, two.code_details.last.content
    three = CodeTicket.find(3)
    assert_equal "rodney", three.code_commits.first.support_identity.name
    assert_equal "verified by bofh", three.status_line
    assert_equal %Q{staged -> verified}, three.code_details.last.content
    four = CodeTicket.find(4)
    assert_equal "waiting for verification (commited by rodney)", four.status_line
    assert_equal %Q{committed -> staged}, four.code_details.last.content
    five = CodeTicket.find(5)
    assert_equal "committed by blair", five.status_line
    assert_equal %Q{taken -> committed (4)}, five.code_details.last.content
    six = CodeTicket.find(6)
    assert_equal "deployed in 1.0 (verified by rodney)", six.status_line
    assert_match %Q{verified -> closed (1)}, six.code_details.last.content
  end
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
  test "vote" do
    ticket = CodeTicket.find(1)
    assert_equal 1, ticket.vote_count
    User.current_user = nil
    assert_raise(RuntimeError) { ticket.vote! }
    User.current_user = User.find_by_login("dean")
    assert ticket.vote!
    assert_raise(RuntimeError) { ticket.vote! }
    assert_equal 2, ticket.vote_count
    User.current_user = User.find_by_login("john")
    assert_nil ticket.voted?
    assert ticket.vote!
    assert_equal 3, ticket.vote_count
  end
  test "indirect votes new ticket" do
    support_ticket = SupportTicket.find(1)
    User.current_user = User.find_by_login("sam")
    assert code_ticket = support_ticket.needs_fix!
    assert_equal 3, code_ticket.vote_count
  end
  test "indirect votes old ticket" do
    support_ticket = SupportTicket.find(1)
    code_ticket = CodeTicket.find(1)
    assert_equal 1, code_ticket.vote_count
    User.current_user = User.find_by_login("sam")
    assert code_ticket = support_ticket.needs_fix!(code_ticket.id)
    assert_equal 3, code_ticket.vote_count
  end
  test "watch" do
    ticket = CodeTicket.find(1)
    User.current_user = nil
    assert_raise(RuntimeError) { ticket.watch! }
    assert_equal 0, ticket.mail_to.size
    User.current_user = User.find_by_login("dean")
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
  end
  test "comment on unowned ticket" do
    ticket = CodeTicket.find(1)
    User.current_user = nil
    assert_raise(RuntimeError) { ticket.comment!("something") }
    assert_equal 0, ticket.code_details.count
    User.current_user = User.find_by_login("dean")
    assert ticket.comment!("user")
    assert_equal 1, ticket.code_details.count
    assert_match "dean wrote", ticket.code_details.first.info
    assert_equal "user", ticket.code_details.first.content
    User.current_user = User.find_by_login("sam")
    assert ticket.comment!("volunteer")
    assert_equal 2, ticket.code_details.count
    assert_match "sam (volunteer) wrote", ticket.code_details.last.info
    assert_equal "volunteer", ticket.code_details.last.content
    assert ticket.comment!("unofficial volunteer", false)
    assert_equal 3, ticket.code_details.count
    assert_match "sam wrote", ticket.code_details.last.info
    assert_equal "unofficial volunteer", ticket.code_details.last.content
  end
  test "comment on owned ticket" do
    ticket = CodeTicket.find(2)
    assert_equal 1, ticket.code_details.count
    User.current_user = User.find_by_login("dean")
    assert_raise(RuntimeError) { ticket.comment!("something") }
    assert_equal 1, ticket.code_details.count
    User.current_user = User.find_by_login("sam")
    assert ticket.comment!("important stuff")
    assert_equal 2, ticket.code_details.count
    assert_equal "important stuff", ticket.code_details.last.content
    assert_match "sam (volunteer) wrote", ticket.code_details.last.info
    assert_raise(RuntimeError) { ticket.comment!("unofficial comment", false) }
    assert_equal 2, ticket.code_details.count
  end
end
