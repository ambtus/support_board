require 'test_helper'

class CodeTicketWorkflowTest < ActiveSupport::TestCase
  test "stealable? not logged in" do
    assert_raise(SecurityError) { CodeTicket.first.stealable? }
  end
  test "stealable? not volunteer" do
    User.current_user = User.find_by_login("jim")
    assert_raise(SecurityError) { CodeTicket.first.stealable? }
  end
  test "stealable? own ticket" do
    User.current_user = User.find_by_login("sam")
    assert !CodeTicket.find(2).stealable?
  end
  test "stealable? wrong state" do
    User.current_user = User.find_by_login("sam")
    assert !CodeTicket.find(4).stealable?
  end
  test "stealable? okay" do
    User.current_user = User.find_by_login("blair")
    assert CodeTicket.find(2).stealable?
  end
  test "scopes" do
    assert_equal 8, CodeTicket.all.count
    assert_equal 5, CodeTicket.not_closed.count
    assert_equal [1], CodeTicket.unowned.ids
    assert_equal [2], CodeTicket.taken.ids
    assert_equal [5], CodeTicket.committed.ids
    assert_equal [4], CodeTicket.staged.ids
    assert_equal [3], CodeTicket.verified.ids
    assert_equal [6, 7, 8], CodeTicket.closed.ids
    assert_equal [5, 2, 1], CodeTicket.for_matching.ids
  end
  test "take" do
    ticket = CodeTicket.find(1)
    assert ticket.unowned?
    User.current_user = User.find_by_login("sam")
    assert ticket.take!
    assert ticket.taken?
    assert_equal "unowned -> taken", ticket.code_details.system_log.last.content
    assert_equal "sam", ticket.support_identity.name
  end
  test "take raise_unless_volunteer" do
    ticket = CodeTicket.find(1)
    assert_raise(SecurityError) { ticket.take! }
    User.current_user = User.find_by_login("jim")
    assert_raise(SecurityError) { ticket.take! }
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
    assert_equal ["sam@ao3.org", "blair@ao3.org"], ticket.mail_to
    dupe = CodeTicket.find(2)
    User.current_user = User.find_by_login("john")
    dupe.watch!
    assert_equal ["sam@ao3.org", "john@ao3.org"], dupe.mail_to
    User.current_user = User.find_by_login("rodney")
    assert dupe.duplicate!(ticket.id)
    assert_equal 0, dupe.reload.mail_to.size
    assert_equal ["sam@ao3.org", "blair@ao3.org", "john@ao3.org"], ticket.reload.mail_to
    assert_equal 3, ticket.code_notifications.size
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
  test "commit with bad code_commit" do
    ticket = CodeTicket.first
    User.current_user = User.find_by_login("sam")
    assert_raise(ActiveRecord::RecordNotFound) { ticket.commit!(19) }
  end
  test "commit with used code_commit" do
    ticket = CodeTicket.first
    User.current_user = User.find_by_login("sam")
    assert_raise(RuntimeError) { ticket.commit!(2) }
  end
  test "commit" do
    commit = CodeCommit.first
    assert commit.unmatched?
    ticket = CodeTicket.first
    assert ticket.unowned?
    User.current_user = User.find_by_login("sam")
    assert ticket.commit!(commit.id)
    assert ticket.committed?
    assert commit.reload.matched?
    assert_equal "sam", ticket.support_identity.name
  end
  test "commit someone else's commit" do
    commit = CodeCommit.first
    ticket = CodeTicket.first
    User.current_user = User.find_by_login("rodney")
    assert ticket.commit!(commit.id)
    assert ticket.committed?
    assert commit.reload.matched?
    assert_equal "sam", ticket.support_identity.name
  end
  test "reject" do
    reason = "not reproducible"
    ticket = CodeTicket.find(1)
    User.current_user = User.find_by_login("sam")
    assert_raise(SecurityError) { ticket.reject!(reason) }
    User.current_user = User.find_by_login("rodney")
    assert ticket.reject!(reason)
    assert_equal "closed by rodney", ticket.status_line
    assert_equal %Q{unowned -> closed (#{reason})}, ticket.code_details.last.content
  end
  test "reject with no reason" do
    ticket = CodeTicket.first
    User.current_user = User.find_by_login("sam")
    assert_raise(SecurityError) { ticket.reject!("reason") }
  end
  test "reject if not admin" do
    ticket = CodeTicket.first
    User.current_user = User.find_by_login("sidra")
    assert_raise(RuntimeError) { ticket.reject!("") }
  end
  test "steal" do
    ticket = CodeTicket.find(2)
    User.current_user = User.find_by_login("rodney")
    assert ticket.steal!
    assert_equal "taken by rodney", ticket.reload.status_line
  end
  test "steal from self" do
    ticket = CodeTicket.find(2)
    User.current_user = User.find_by_login("sam")
    assert_raise(RuntimeError) { ticket.steal! }
  end
  test "steal raise_unless_volunteer" do
    ticket = CodeTicket.find(2)
    assert_raise(SecurityError) { ticket.steal! }
    User.current_user = User.find_by_login("jim")
    assert_raise(SecurityError) { ticket.steal! }
  end
  test "steal not in stealable state" do
    ticket = CodeTicket.find(1)
    User.current_user = User.find_by_login("sam")
    assert_raise(Workflow::NoTransitionAllowed) { ticket.steal! }
  end
  test "reopen taken" do
    reason = "sorry, I don't have time to save the world this month"
    ticket = CodeTicket.find(2)
    User.current_user = User.find_by_login("sam")
    assert ticket.reopen!(reason)
    assert_equal "open", ticket.status_line
    assert_equal %Q{taken -> unowned (#{reason})}, ticket.code_details.last.content
    assert_nil ticket.support_identity_id
  end
  test "reopen dupe" do
    reason = "these aren't the same"
    ticket = CodeTicket.find(8)
    assert ticket.code_ticket
    User.current_user = User.find_by_login("sam")
    assert ticket.reopen!(reason)
    assert_equal "open", ticket.status_line
    assert_equal %Q{closed -> unowned (#{reason})}, ticket.code_details.last.content
    assert_nil ticket.support_identity_id
    assert_nil ticket.reload.code_ticket
  end
  test "reopen deployed" do
    reason = "try again"
    ticket = CodeTicket.find(6)
    assert ticket.release_note
    User.current_user = User.find_by_login("sam")
    assert ticket.reopen!(reason)
    assert_equal "open", ticket.status_line
    assert_equal %Q{closed -> unowned (#{reason})}, ticket.code_details.last.content
    assert_nil ticket.support_identity_id
    assert_nil ticket.reload.release_note
  end
  test "stage" do
    ticket = CodeTicket.find(5)
    assert "blair", ticket.support_identity.name
    assert ticket.code_commits.first.matched?
    User.current_user = User.find_by_login("sidra")
    assert ticket.stage!
    assert "blair", ticket.reload.support_identity.name
    assert ticket.code_commits.first.staged?
  end
  test "stage non-admin" do
    ticket = CodeTicket.find(5)
    User.current_user = User.find_by_login("sam")
    assert_raise(SecurityError) { ticket.stage! }
  end
  test "verify" do
    ticket = CodeTicket.find(4)
    assert ticket.staged?
    assert "rodney", ticket.support_identity.name
    assert ticket.code_commits.first.staged?
    User.current_user = User.find_by_login("sam")
    assert ticket.verify!
    assert "sam", ticket.reload.support_identity.name
    assert ticket.verified?
    assert ticket.code_commits.first.verified?
  end
  test "verify own ticket" do
    ticket = CodeTicket.find(4)
    User.current_user = User.find_by_login("rodney")
    assert_raise(RuntimeError) { ticket.verify! }
  end
  test "deploy" do
    ticket = CodeTicket.find(3)
    assert ticket.code_commits.first.verified?
    assert ticket.support_tickets.first.waiting?
    assert "sidra", ticket.support_identity.name
    assert ticket.code_commits.first.verified?
    User.current_user = User.find_by_login("sidra")
    assert ticket.deploy!(ReleaseNote.first.id)
    assert "sidra", ticket.reload.support_identity.name
    assert ticket.code_commits.first.deployed?
    assert ticket.support_tickets.first.closed?
  end
  test "deploy non-admin" do
    ticket = CodeTicket.find(3)
    User.current_user = User.find_by_login("sam")
    assert_raise(SecurityError) { ticket.deploy!(2) }
  end
  test "deploy no release note" do
    ticket = CodeTicket.find(3)
    User.current_user = User.find_by_login("sidra")
    assert_raise(ActiveRecord::RecordNotFound) { ticket.deploy!(17) }
  end
  test "stage all - not admin" do
    User.current_user = User.find_by_login("sam")
    assert_raise(SecurityError) { CodeTicket.stage! }
  end
  test "stage all - not all code commits matched" do
    User.current_user = User.find_by_login("sidra")
    assert_equal 1, CodeCommit.unmatched.count
    assert_raise(RuntimeError) { CodeTicket.stage! }
  end
  test "stage all" do
    assert_not_empty CodeTicket.committed
    User.current_user = User.find_by_login("sidra")
    assert CodeTicket.find(1).commit!(CodeCommit.find(1))
    assert CodeTicket.stage!
    assert_empty CodeTicket.committed
  end
  test "deploy all - not admin" do
    User.current_user = User.find_by_login("sam")
    assert_raise(SecurityError) { CodeTicket.deploy!(2) }
  end
  test "deploy all - not all code tickets verified" do
    User.current_user = User.find_by_login("sidra")
    assert_equal 1, CodeTicket.staged.count
    assert_raise(RuntimeError) { CodeTicket.deploy!(2) }
  end
  test "deploy all - non-existent release note" do
    User.current_user = User.find_by_login("sidra")
    assert_raise(RuntimeError) { CodeTicket.deploy!(17) }
  end
  test "deploy all" do
    assert_not_empty CodeTicket.staged
    assert_not_empty CodeTicket.verified
    User.current_user = User.find_by_login("sidra")
    CodeTicket.staged.each {|ct| ct.verify! }
    assert CodeTicket.deploy!(2)
    assert_empty CodeTicket.staged
    assert_empty CodeTicket.verified
  end
end
