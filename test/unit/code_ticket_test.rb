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
end
