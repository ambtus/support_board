require 'test_helper'

class CodeTicketNotificationTest < ActiveSupport::TestCase
  test "watched?" do
    # FIXME
  end
  test "watch" do
    ticket = CodeTicket.find(1)
    assert_raise(RuntimeError) { ticket.watch! }
    assert_equal 1, ticket.mail_to.size
    User.current_user = User.find_by_login("dean")
    assert_raise(RuntimeError) { ticket.unwatch! }
    assert ticket.watch!
    assert_equal 2, ticket.mail_to.size
    assert ticket.watch! # no-op
    assert_equal 2, ticket.mail_to.size
    User.current_user = User.find_by_login("john")
    assert_nil ticket.watched?
    assert ticket.watch!
    assert_equal 3, ticket.mail_to.size
    assert ticket.unwatch!
    assert_equal 2, ticket.reload.mail_to.size
    assert_nil ticket.watched?
  end
end
