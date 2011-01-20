require 'test_helper'

class CodeTicketTest < ActiveSupport::TestCase
  test "create with validations" do
    assert_raise(ActiveRecord::RecordInvalid) { CodeTicket.create! }
    assert CodeTicket.create(:summary => "short summary")
    assert_raise(ActiveRecord::RecordInvalid) { CodeTicket.create!(:summary => SecureRandom.hex(141))}
  end
  test "name" do
    assert_equal "Code Ticket #1", CodeTicket.find(1).name
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
