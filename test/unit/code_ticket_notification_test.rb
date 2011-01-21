require 'test_helper'

class CodeTicketNotificationTest < ActiveSupport::TestCase
  test "watched? not logged in" do
    ticket = CodeTicket.find(1)
    assert_raise(RuntimeError) { ticket.watched? }
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
    assert_equal ["rodney@ao3.org", "bofh@ao3.org"], CodeTicket.find(3).mail_to
    assert_equal ["rodney@ao3.org", "john@ao3.org", "bofh@ao3.org", "blair@ao3.org"], CodeTicket.find(4).mail_to
    assert_equal ["blair@ao3.org", "jim@ao3.org"], CodeTicket.find(5).mail_to
    assert_equal ["bofh@ao3.org", "rodney@ao3.org"], CodeTicket.find(6).mail_to
    assert_equal ["sam@ao3.org", "rodney@ao3.org", "blair@ao3.org"], CodeTicket.find(7).mail_to
    assert_equal [], CodeTicket.find(8).mail_to
  end
  test "mail_to private" do
    # FIXME
  end
end
