require 'test_helper'

class SupportTicketNotificationTest < ActiveSupport::TestCase
  test "a guest ticket with default owner notifications" do
    assert ticket = SupportTicket.create!(:summary => "something short", :email => "guest@ao3.org")
    assert_nil ticket.user
    assert_equal ["guest@ao3.org"], ticket.mail_to
  end
  test "a user ticket with default owner notifications" do
    dean = User.find_by_login("dean")
    User.current_user = dean
    assert ticket = SupportTicket.create!(:summary => "something short")
    assert_equal ["dean@ao3.org"], ticket.mail_to
  end
  test "create a guest ticket without notifications" do
    assert ticket = SupportTicket.create!(:summary => "something short", :email => "guest@ao3.org", :turn_off_notifications => "1")
    assert_nil ticket.user
    assert_equal [], ticket.mail_to
  end
  test "create a user ticket without notifications" do
    dean = User.find_by_login("dean")
    User.current_user = dean
    assert ticket = SupportTicket.create!(:summary => "something short", :turn_off_notifications => "1")
    assert_equal [], ticket.mail_to
  end
  test "watch guest ticket" do
    ticket = SupportTicket.find(1)
    assert_equal 1, ticket.support_notifications.size
    User.current_user = nil
    assert ticket.watch!(ticket.authentication_code)
    assert_equal 1, ticket.reload.support_notifications.size
    assert ticket.unwatch!(ticket.authentication_code)
    assert_equal 0, ticket.reload.support_notifications.size
    assert !ticket.watched?(ticket.authentication_code)
    User.current_user = User.find_by_login("dean")
    assert_nil ticket.watched?
    assert_raise(RuntimeError) { ticket.unwatch! }
    assert ticket.watch!
    assert_equal 1, ticket.support_notifications.size
    assert ticket.watch!
    assert_equal 1, ticket.support_notifications.size
    User.current_user = User.find_by_login("john")
    assert_nil ticket.watched?
    assert ticket.watch!
    assert_equal 2, ticket.support_notifications.size
    assert ticket.unwatch!
    assert_equal 1, ticket.reload.support_notifications.size
    assert_nil ticket.watched?
    User.current_user = nil
    assert ticket.watch!(ticket.authentication_code)
    assert_equal 2, ticket.support_notifications.size
    assert ticket.make_private!(ticket.authentication_code)
    assert_equal 1, ticket.reload.support_notifications.size
    assert_equal "made private", ticket.support_details.last.content
    User.current_user = User.find_by_login("john")
    assert_nil ticket.watched?
    assert_raise(SecurityError) { ticket.watch! }
    User.current_user = User.find_by_login("sam")
    assert_nil ticket.watched?
    assert ticket.watch!
    assert_equal 2, ticket.support_notifications.size
  end
  test "watch user ticket" do
    ticket = SupportTicket.find(3)
    User.current_user = User.find_by_login("sam")
    assert ticket.watched?
    assert_equal 2, ticket.support_notifications.size
    User.current_user = nil
    assert_raise(SecurityError) { ticket.watch! }
    User.current_user = User.find_by_login("dean")
    assert_equal 2, ticket.support_notifications.size
    assert ticket.watched?
    assert ticket.watch!
    assert_equal 2, ticket.support_notifications.size
    User.current_user = User.find_by_login("john")
    assert_nil ticket.watched?
    assert ticket.watch!
    assert_equal 3, ticket.support_notifications.size
    assert ticket.watched?
    User.current_user = User.find_by_login("dean")
    assert ticket.make_private!
    assert_equal 2, ticket.reload.support_notifications.size
    assert_equal "made private", ticket.support_details.last.content
    User.current_user = User.find_by_login("john")
    assert_nil ticket.watched?
    assert_raise(SecurityError) { ticket.watch! }
  end
end
