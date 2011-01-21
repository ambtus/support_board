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
    assert_equal "verified by bofh",  CodeTicket.find(3).status_line
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
