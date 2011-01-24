require 'test_helper'

class CodeTicketTest < ActiveSupport::TestCase
  test "create with validations and callbacks" do
    assert_raise(SecurityError) { CodeTicket.create!(:summary => "short summary") }
    User.current_user = User.find_by_login("jim")
    assert_raise(SecurityError) { CodeTicket.create!(:summary => "short summary") }
    User.current_user = User.find_by_login("sam")
    assert_raise(ActiveRecord::RecordInvalid) { CodeTicket.create! }
    assert_raise(ActiveRecord::RecordInvalid) { CodeTicket.create!(:summary => SecureRandom.hex(141))}
    assert ticket = CodeTicket.create(:summary => "short summary")
    assert_equal ["sam@ao3.org"], ticket.mail_to
  end
  test "name" do
    assert_equal "Code Ticket #1", CodeTicket.find(1).name
  end
  test "status_line" do
    assert_equal "open", CodeTicket.find(1).status_line
    assert_equal "taken by sam", CodeTicket.find(2).status_line
    assert_equal "verified by sidra",  CodeTicket.find(3).status_line
    assert_equal "waiting for verification (commited by rodney)", CodeTicket.find(4).status_line
    assert_equal "committed by blair", CodeTicket.find(5).status_line
    assert_equal "deployed in 1.0 (verified by rodney)", CodeTicket.find(6).status_line
    assert_equal "deployed in 2.0 (verified by blair)", CodeTicket.find(7).status_line
    assert_equal "closed as duplicate by sam", CodeTicket.find(8).status_line
  end
  test "voted? not logged in" do
    assert_raise(SecurityError) { CodeTicket.first.voted? }
  end
  test "voted? when true" do
    User.current_user = User.find_by_login("sam")
    assert CodeTicket.first.voted?
  end
  test "voted? when false" do
    User.current_user = User.find_by_login("blair")
    assert !CodeTicket.first.voted?
  end
  test "vote_count" do
    assert_equal 1, CodeTicket.find(1).vote_count
    assert_equal 4, CodeTicket.find(2).vote_count
    assert_equal 5, CodeTicket.find(3).vote_count
    assert_equal 0, CodeTicket.find(4).vote_count
    assert_equal 2, CodeTicket.find(5).vote_count
    assert_equal 1, CodeTicket.find(6).vote_count
    assert_equal 3, CodeTicket.find(7).vote_count
    assert_equal 0, CodeTicket.find(8).vote_count
  end
  test "sort (by vote)" do
    assert_equal [3, 2, 5, 1, 4], CodeTicket.not_closed.sort.map(&:id)
  end
  test "vote not logged in" do
    assert_raise(SecurityError) { CodeTicket.first.vote! }
  end
  test "vote for duplicate" do
    User.current_user = User.find_by_login("jim")
    assert_raise(RuntimeError) { CodeTicket.find(8).vote! }
  end
  test "vote already voted" do
    ticket = CodeTicket.find(2)
    User.current_user = User.find_by_login("rodney")
    assert ticket.voted?
    assert_raise(RuntimeError) { ticket.vote! }
  end
  test "vote" do
    ticket = CodeTicket.find(1)
    assert_equal 1, ticket.code_votes.count
    assert_equal 1, ticket.vote_count
    User.current_user = User.find_by_login("rodney")
    assert !ticket.voted?
    assert ticket.vote!
    assert_equal 2, ticket.code_votes.count
    assert_equal 2, ticket.vote_count
  end
  test "vote different amount" do
    ticket = CodeTicket.find(1)
    assert_equal 1, ticket.vote_count
    User.current_user = User.find_by_login("rodney")
    assert ticket.vote!(7)
    assert_equal 8, ticket.vote_count
  end
  test "update not logged in" do
    assert_raise(SecurityError) { CodeTicket.first.update_from_edit!("new summary", "", "") }
  end
  test "update not volunteer" do
    User.current_user = User.find_by_login("jim")
    assert_raise(SecurityError) { CodeTicket.first.update_from_edit!("new summary", "", "") }
  end
  test "update summary validation" do
    User.current_user = User.find_by_login("sam")
    assert_raise(ActiveRecord::RecordInvalid) { CodeTicket.first.update_from_edit!("", "", "") }
    assert_raise(ActiveRecord::RecordInvalid) { CodeTicket.first.update_from_edit!(SecureRandom.hex(141), "", "") }
  end
  test "update from edit" do
    ticket = CodeTicket.first
    assert_equal "fix the roof", ticket.summary
    assert_nil ticket.url
    assert_nil ticket.browser
    User.current_user = User.find_by_login("sam")
    ticket.update_from_edit!("repair the roof", "/roof/1", "safari on iPhone")
    ticket.reload
    assert_equal "repair the roof", ticket.summary
    assert_equal "/roof/1", ticket.url
    assert_equal "safari on iPhone", ticket.browser
    assert_equal "ticket edited", ticket.code_details.last.content
    assert_equal "sam (volunteer)", ticket.code_details.last.byline
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
end
