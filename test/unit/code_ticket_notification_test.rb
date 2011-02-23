require 'test_helper'

class CodeTicketNotificationTest < ActiveSupport::TestCase
  test "create without notification" do
    User.current_user = User.find_by_login("sam")
    assert ticket = CodeTicket.create(:summary => "short summary", :turn_off_notifications => "1")
    assert_equal [], ticket.mail_to
  end
  test "watched? not logged in" do
    ticket = CodeTicket.find(1)
    assert_raise(SecurityError) { ticket.watched? }
  end
  test "watched? not watching" do
    ticket = CodeTicket.find(1)
    User.current_user = User.find_by_login("dean")
    assert !ticket.watched?
  end
  test "watched? watching" do
    ticket = CodeTicket.find(1)
    User.current_user = User.find_by_login("sam")
    assert ticket.watched?
  end
  test "mail_to" do
    assert_equal ["sam@ao3.org", "blair@ao3.org"], CodeTicket.find(1).mail_to
    assert_equal ["sam@ao3.org"], CodeTicket.find(2).mail_to
    assert_equal ["rodney@ao3.org", "sidra@ao3.org"], CodeTicket.find(3).mail_to
    assert_equal ["rodney@ao3.org", "john@ao3.org", "sidra@ao3.org", "blair@ao3.org"], CodeTicket.find(4).mail_to
    assert_equal ["blair@ao3.org", "jim@ao3.org"], CodeTicket.find(5).mail_to
    assert_equal ["sidra@ao3.org", "rodney@ao3.org"], CodeTicket.find(6).mail_to
    assert_equal ["sam@ao3.org", "rodney@ao3.org", "blair@ao3.org"], CodeTicket.find(7).mail_to
    assert_equal [], CodeTicket.find(8).mail_to
  end
  test "mail_to private" do
    assert_equal ["rodney@ao3.org", "sidra@ao3.org", "blair@ao3.org"], CodeTicket.find(4).mail_to(true)
    assert_equal ["blair@ao3.org"], CodeTicket.find(5).mail_to(true)
    assert_equal ["sam@ao3.org", "rodney@ao3.org", "blair@ao3.org"], CodeTicket.find(7).mail_to(true)
    assert_equal [], CodeTicket.find(8).mail_to(true)
  end
  test "watch! not logged in" do
    assert_raise(SecurityError) { CodeTicket.find(1).watch! }
  end
  test "watch! duplicate" do
    User.current_user = User.find_by_login("jim")
    assert_raise(RuntimeError) { CodeTicket.find(8).watch! }
  end
  test "watch! already watching" do
    ticket = CodeTicket.find(5)
    assert_equal 2, ticket.code_notifications.count
    User.current_user = User.find_by_login("jim")
    assert ticket.watched?
    assert ticket.watch!
    assert_equal 2, ticket.code_notifications.count
  end
  test "watch! not watching" do
    ticket = CodeTicket.find(5)
    assert_equal 2, ticket.code_notifications.count
    User.current_user = User.find_by_login("john")
    assert !ticket.watched?
    assert ticket.watch!
    assert ticket.watched?
    assert_equal 3, ticket.code_notifications.count
  end
  test "unwatch! not logged in" do
    assert_raise(SecurityError) { CodeTicket.find(1).unwatch! }
  end
  test "unwatch! not watching" do
    ticket = CodeTicket.find(5)
    User.current_user = User.find_by_login("john")
    assert !ticket.watched?
    assert_raise(RuntimeError) { ticket.unwatch! }
  end
  test "unwatch! watching" do
    ticket = CodeTicket.find(5)
    assert_equal 2, ticket.code_notifications.count
    User.current_user = User.find_by_login("jim")
    assert ticket.watched?
    assert ticket.unwatch!
    assert !ticket.watched?
    assert_equal 1, ticket.code_notifications.count
  end
  # etst sending notifications in cucumber so can inspect the views
end
