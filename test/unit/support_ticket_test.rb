require 'test_helper'

# validation, callback and helper methods (first part of support_ticket.rb)
class SupportTicketTest < ActiveSupport::TestCase
  test "create guest ticket with validations" do
    assert_raise(ActiveRecord::RecordInvalid) { SupportTicket.create! }
    assert_raise(ActiveRecord::RecordInvalid) { SupportTicket.create!(:summary => "something short") }
    assert_raise(ActiveRecord::RecordInvalid) { SupportTicket.create!(:summary => "something short",
                                                                      :email => "an invalid address") }
    assert_raise(ActiveRecord::RecordInvalid) { SupportTicket.create!(:summary => SecureRandom.hex(141),
                                                                      :email => "guest@ao3.org") }
    assert ticket = SupportTicket.create!(:summary => "something short", :email => "guest@ao3.org")
    assert_nil ticket.user
    assert ticket.authentication_code
    assert_equal "guest@ao3.org", ticket.email
    assert_equal "something short", ticket.summary
  end
  test "create user ticket with validations" do
    User.current_user = User.first
    assert_raise(ActiveRecord::RecordInvalid) { SupportTicket.create! }
    assert_raise(ActiveRecord::RecordInvalid) { SupportTicket.create!(:summary => SecureRandom.hex(141)) }
    assert ticket = SupportTicket.create!(:summary => "something short")
    assert_equal User.first, ticket.user
    assert_nil ticket.email
    assert_nil ticket.authentication_code
    assert_equal "something short", ticket.summary
  end
  test "if try to create a guest ticket when logged in, get a user ticket" do
    User.current_user = User.first
    assert ticket = SupportTicket.create!(:summary => "something short", :email => "guest@ao3.org")
    assert_equal User.first, ticket.user
    assert_nil ticket.email
    assert_nil ticket.authentication_code
  end
  test "browser string" do
    assert_equal "Chrome 10.0.638.0 (Windows 7)", SupportTicket.first.browser_string
    assert_equal "Internet Explorer 8.0 (Windows XP)", SupportTicket.find(3).browser_string
    assert_equal "Safari 5.0.3 (OS X)", SupportTicket.find(4).browser_string
    assert_equal "Firefox 3.6.13 (OS X)", SupportTicket.find(6).browser_string
    assert_equal "BlackBerry  (BlackBerryOS)", SupportTicket.find(12).browser_string
  end
  test "name" do
    assert_equal "Support Ticket #1", SupportTicket.find(1).name
  end
  test "parens" do
    assert_equal "(a guest)", SupportTicket.first.parens
    assert_equal "(a guest [Private])", SupportTicket.find(2).parens
    assert_equal "(a user)", SupportTicket.find(7).parens
    assert_equal "(a user [Private])", SupportTicket.find(4).parens
    assert_equal "(dean)", SupportTicket.find(3).parens
    assert_equal "(john [Private])", SupportTicket.find(5).parens
  end
  test "status lines" do
    assert_equal "open", SupportTicket.find(1).status_line
    assert_equal "waiting for a code fix", SupportTicket.find(4).status_line
    assert_equal "waiting for an admin", SupportTicket.find(17).status_line
    assert_equal "spam", SupportTicket.find(2).status_line
    assert_equal "closed by owner", SupportTicket.find(22).status_line
    assert_equal "fixed in release", SupportTicket.find(18).status_line
    assert_equal "answered by FAQ", SupportTicket.find(5).status_line # faq
    assert_equal "answered by FAQ", SupportTicket.find(6).status_line # rfc
    assert_equal "taken by sam", SupportTicket.find(3).status_line
    assert_equal "posted by blair", SupportTicket.find(10).status_line
    assert_equal "closed by sidra", SupportTicket.find(19).status_line # resolved by admin
  end
  test "guest ticket?" do
    assert SupportTicket.find(1).guest_ticket?
    assert !SupportTicket.find(3).guest_ticket?
  end
  test "owner? of guest ticket as guest" do
    ticket = SupportTicket.find(1)
    # no code
    assert !ticket.owner?
    # wrong code
    assert !ticket.owner?("eeng0phaighjieTh")
    # correct code
    assert ticket.owner?(ticket.authentication_code)
  end
  test "owner? of guest ticket as user" do
    ticket = SupportTicket.find(1)
    User.current_user = User.find_by_login("sidra")
    assert !ticket.owner?
    assert !ticket.owner?(ticket.authentication_code)
  end
  test "owner? of user ticket as guest" do
    ticket = SupportTicket.find(3)
    assert !ticket.owner?
  end
  test "owner? of user ticket as owner" do
    ticket = SupportTicket.find(3)
    dean = User.find_by_login("dean")
    assert_equal dean, ticket.user
    User.current_user = dean
    assert ticket.owner?
  end
  test "owner? of user ticket as user who is not owner" do
    ticket = SupportTicket.find(3)
    User.current_user = User.find_by_login("sidra")
    assert !ticket.owner?
  end
  test "watched? of guest ticket as guest" do
    ticket = SupportTicket.find(1)
    # no code
    assert_raise(SecurityError) { ticket.watched? }
    # wrong code
    assert_raise(SecurityError) { ticket.watched?("eeng0phaighjieTh") }
    # correct code
    assert ticket.watched?(ticket.authentication_code)
  end
  test "watched? of guest ticket as user" do
    ticket = SupportTicket.find(1)
    User.current_user = User.find_by_login("sidra")
    assert_raise(SecurityError) { ticket.watched?(ticket.authentication_code) }
    assert !ticket.watched?
  end
  test "watched? of user ticket as guest" do
    ticket = SupportTicket.find(3)
    assert_raise(SecurityError) { ticket.watched? }
  end
  test "watched? of user ticket as owner" do
    ticket = SupportTicket.find(3)
    dean = User.find_by_login("dean")
    assert_equal dean, ticket.user
    User.current_user = dean
    assert ticket.watched?
  end
  test "watched? of user ticket as user who is not owner" do
    ticket = SupportTicket.find(3)
    User.current_user = User.find_by_login("sidra")
    assert !ticket.watched?
  end
  test "public_watcher? when guest" do
    ticket = SupportTicket.find(3)
    assert !ticket.public_watcher?
  end
  test "public_watcher? when user owner" do
    ticket = SupportTicket.find(3)
    User.current_user = User.find_by_login("dean")
    assert !ticket.public_watcher?
  end
  test "public_watcher? when volunteer" do
    ticket = SupportTicket.find(3)
    User.current_user = User.find_by_login("sam")
    assert !ticket.public_watcher?
  end
  test "public_watcher? when user" do
    ticket = SupportTicket.find(3)
    User.current_user = User.find_by_login("jim")
    assert ticket.public_watcher?
  end
  test "stealable? when guest" do
    ticket = SupportTicket.find(3)
    assert_equal "taken by sam", ticket.status_line
    assert_raise(SecurityError) { ticket.stealable? }
  end
  test "stealable? when user" do
    ticket = SupportTicket.find(3)
    User.current_user = User.find_by_login("jim")
    assert_raise(SecurityError) { ticket.stealable? }
  end
  test "stealable? when volunteer" do
    ticket = SupportTicket.find(3)
    User.current_user = User.find_by_login("blair")
    assert ticket.stealable?
  end
  test "stealable? when already taken" do
    ticket = SupportTicket.find(3)
    User.current_user = User.find_by_login("sam")
    assert !ticket.stealable?
  end
  test "take_and_watch and mail_to" do
    # no take_and_watch on unowned tickets
    assert_nil SupportTicket.find(1).support_identity_id
    # no take_and_watch on unowned tickets even if opened by volunteer
    assert_nil SupportTicket.find(8).support_identity_id
    # no take_and_watch on needs_admin tickets
    assert_nil SupportTicket.find(17).support_identity_id
    assert !SupportTicket.find(17).mail_to.include?("blair@ao3.org")
    # spam! calls take_and_watch
    assert_equal "sam", SupportTicket.find(2).support_identity.name
    assert_includes SupportTicket.find(2).mail_to, "sam@ao3.org"
    # take! calls take_and_watch
    assert_equal "sam", SupportTicket.find(3).support_identity.name
    assert_includes SupportTicket.find(3).mail_to, "sam@ao3.org"
    # steal! calls take_and_watch
    User.current_user = User.find_by_login("blair")
    SupportTicket.find(3).steal!
    assert_equal "blair", SupportTicket.find(3).support_identity.name
    assert_includes SupportTicket.find(3).mail_to, "blair@ao3.org"
    # needs_fix! calls take_and_watch
    assert_equal "rodney", SupportTicket.find(4).support_identity.name
    assert_includes SupportTicket.find(4).mail_to, "rodney@ao3.org"
    # answer! calls take_and_watch
    assert_equal "rodney", SupportTicket.find(5).support_identity.name
    assert_includes SupportTicket.find(5).mail_to, "rodney@ao3.org"
    # post! calls take_and_watch
    assert_equal "blair", SupportTicket.find(10).support_identity.name
    assert_includes SupportTicket.find(10).mail_to, "blair@ao3.org"
    # resolve! calls take_and_watch
    assert_equal "sidra", SupportTicket.find(19).support_identity.name
    assert_includes SupportTicket.find(19).mail_to, "sidra@ao3.org"
  end
end
