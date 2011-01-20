require 'test_helper'

class SupportTicketCommentTest < ActiveSupport::TestCase
  test "system logs" do
    assert_equal %Q{unowned -> spam}, SupportTicket.find(2).support_details.system_log.last.content
    assert_equal %Q{unowned -> taken}, SupportTicket.find(3).support_details.system_log.last.content
    assert_equal %Q{unowned -> waiting (3)}, SupportTicket.find(4).support_details.system_log.last.content
    assert_equal %Q{unowned -> closed (4)}, SupportTicket.find(5).support_details.system_log.last.content
    assert_equal %Q{unowned -> closed (5)}, SupportTicket.find(6).support_details.system_log.last.content
  end
  # guest comments
  test "not logged in can't comment on unowned guest ticket if email doesn't match" do
    ticket = SupportTicket.find(1)
    assert_raise(SecurityError) { ticket.comment!("something") }
    assert_raise(SecurityError) { ticket.comment!("something", false, "someone@ao3.org") }
    assert_raise(SecurityError) { ticket.comment!("something", false, "happy@ao3.org") }
    assert_raise(SecurityError) { ticket.comment!("something", true, "sam@ao3.org") }
  end
  test "not logged in can't comment on unowned user ticket" do
    ticket = SupportTicket.find(8)
    assert_raise(SecurityError) { ticket.comment!("something") }
    assert_raise(SecurityError) { ticket.comment!("something", false, "guest@ao3.org") }
    assert_raise(SecurityError) { ticket.comment!("something", false, "sam@ao3.org") }
    assert_raise(SecurityError) { ticket.comment!("something", true, "sam@ao3.org") }
  end
  test "not logged in can comment (anonymous) on unowned guest ticket if email does match" do
    ticket = SupportTicket.find(1)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("I have something to say", false, "guest@ao3.org")
    assert_match "I have something to say", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "not logged in can comment (anonymous) on spam guest ticket if email matches" do
    ticket = SupportTicket.find(2)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("This is not spam!", false, "guest@ao3.org")
    assert_match "This is not spam!", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "not logged in can comment (anonymous) on posted guest ticket if email matches" do
    ticket = SupportTicket.find(11)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("please take this off the comments page", false, "happy@ao3.org")
    assert_match "please take this off the comments page", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "not logged in can comment (anonymous) on waiting guest ticket if email matches" do
    ticket = SupportTicket.find(18)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("looks fine in firefox", false, "guest@ao3.org")
    assert_match "looks fine in firefox", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "not logged in can comment (anonymous) on waiting_on_admin guest ticket if email matches" do
    ticket = SupportTicket.find(17)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("my old email was sad@ao3.org", false, "happy@ao3.org")
    assert_match "my old email was sad@ao3.org", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "not logged in can comment (anonymous) on closed guest ticket if email matches" do
    ticket = SupportTicket.find(19)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("i meant the ff importer is down", false, "guest@ao3.org")
    assert_match "i meant the ff importer is down", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end

  # user comments on tickets not their own
  test "any user can comment (not anonymous) on open tickets" do
    ticket = SupportTicket.find(20)
    assert_equal 0, ticket.support_details.public_comments.count
    User.current_user = User.find_by_login("dean")
    assert ticket.comment!("I have something to add")
    assert_equal "I have something to add", ticket.support_details.last.content
    assert_match "dean wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "if the user isn't official, doesn't get the volunteer designation even if requested" do
    ticket = SupportTicket.find(20)
    assert_equal 0, ticket.support_details.public_comments.count
    User.current_user = User.find_by_login("dean")
    assert ticket.comment!("I have something to add", true)
    assert_equal "I have something to add", ticket.support_details.last.content
    assert_match "dean wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "users can't comment on private tickets even if unowned" do
    ticket = SupportTicket.find(16)
    User.current_user = User.find_by_login("dean")
    assert_raise(SecurityError) { ticket.comment!("user on private ticket") }
  end
  test "users can only comment on unowned tickets" do
    User.current_user = User.find_by_login("newbie")
    ticket = SupportTicket.find(2)
    assert_raise(SecurityError) { ticket.comment!("user on spam ticket") }
    ticket = SupportTicket.find(3)
    assert_raise(SecurityError) { ticket.comment!("user on taken ticket") }
    ticket = SupportTicket.find(14)
    assert_raise(SecurityError) { ticket.comment!("user on posted ticket") }
    ticket = SupportTicket.find(7)
    assert_raise(SecurityError) { ticket.comment!("user on waiting ticket") }
    ticket = SupportTicket.find(17)
    assert_raise(SecurityError) { ticket.comment!("user on waiting_on_admin ticket") }
    ticket = SupportTicket.find(19)
    assert_raise(SecurityError) { ticket.comment!("user on closed ticket") }
  end

  # user comments on their own tickets
  test "owner comments are anonymous if the ticket is anonymous" do
    ticket = SupportTicket.find(20)
    assert_equal 0, ticket.support_details.public_comments.count
    User.current_user = User.find_by_login("john")
    assert ticket.comment!("I have something to add")
    assert_equal "I have something to add", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "comment anonymity changes when ticket anonymity changes" do
    john = User.find_by_login("john")
    ticket = SupportTicket.find(5)
    assert !ticket.anonymous?
    assert_equal john, ticket.user
    assert_equal 0, ticket.support_details.public_comments.count
    User.current_user = john
    assert ticket.comment!("something to say")
    assert_equal 1, ticket.support_details.public_comments.count
    assert_equal "something to say", ticket.support_details.public_comments.first.content
    assert_match "john wrote", ticket.support_details.public_comments.first.info
    assert ticket.hide_username!
    assert ticket.anonymous?
    assert_equal 1, ticket.support_details.public_comments.count
    assert_equal "something to say", ticket.support_details.public_comments.first.content
    assert_match "ticket owner wrote", ticket.support_details.public_comments.first.info
  end
  test "users can comment on taken ticket if it's theirs" do
    User.current_user = User.find_by_login("dean")
    ticket = SupportTicket.find(3)
    assert_equal 1, ticket.support_details.public_comments.count
    assert ticket.comment!("ping")
    assert_match "ping", ticket.support_details.last.content
    assert_match "dean wrote", ticket.support_details.last.info
    assert_equal 2, ticket.support_details.public_comments.count
  end
  test "users can comment on posted ticket if it's theirs" do
    User.current_user = User.find_by_login("newbie")
    ticket = SupportTicket.find(12)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("please take this off the comments page")
    assert_match "please take this off the comments page", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "users can comment on waiting ticket if it's theirs" do
    User.current_user = User.find_by_login("john")
    ticket = SupportTicket.find(4)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("none too soon")
    assert_match "none too soon", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "users can comment on waiting_on_admin ticket if it's theirs" do
    User.current_user = User.find_by_login("dean")
    ticket = SupportTicket.find(21)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("ping")
    assert_match "ping", ticket.support_details.last.content
    assert_match "dean wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "users can comment on closed ticket if it's theirs" do
    User.current_user = User.find_by_login("jim")
    ticket = SupportTicket.find(6)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("thanks")
    assert_match "thanks", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end

  # unofficial volunteer comments
  test "volunteers who comment on their own user tickets unofficially respects anonymity" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(8)
    assert_equal 1, ticket.support_details.public_comments.count
    assert ticket.comment!("i'm warning you", false)
    assert_match "i'm warning you", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 2, ticket.support_details.public_comments.count
    assert ticket.show_username!
    assert_match "sam wrote", ticket.support_details.public_comments.last.info
  end
  test "system log details should respect anonymity for volunteers" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(8)
    ticket.hide_username!
    assert_match "ticket owner", ticket.support_details.system_log.last.info
  end
  test "volunteers can comment on unowned guest tickets unofficially" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(1)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("something random", false)
    assert_match "something random", ticket.support_details.last.content
    assert_match "sam wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "volunteers can comment on unowned user tickets unofficially" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(20)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("hunting is my game", false)
    assert_match "hunting is my game", ticket.support_details.last.content
    assert_match "sam wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "volunteers can't comment on tickets unofficially unless they're unowned" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(2)
    assert_raise(SecurityError) { ticket.comment!("spam ticket", false) }
    ticket = SupportTicket.find(3)
    assert_raise(SecurityError) { ticket.comment!("taken ticket", false) }
    ticket = SupportTicket.find(14)
    assert_raise(SecurityError) { ticket.comment!("posted ticket", false) }
    ticket = SupportTicket.find(7)
    assert_raise(SecurityError) { ticket.comment!("waiting ticket", false) }
    ticket = SupportTicket.find(17)
    assert_raise(SecurityError) { ticket.comment!("waiting_on_admin ticket", false) }
    ticket = SupportTicket.find(19)
    assert_raise(SecurityError) { ticket.comment!("closed ticket", false) }
  end

  # official volunteer comments
  test "volunteers commenting officially are not anonymous even if it's their own anonymous ticket" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(8)
    assert_equal 1, ticket.support_details.public_comments.count
    assert ticket.comment!("i'm warning you", true)
    assert_match "i'm warning you", ticket.support_details.last.content
    assert_match "sam (volunteer) wrote", ticket.support_details.last.info
    assert_equal 2, ticket.support_details.public_comments.count
  end
  test "volunteers can comment on taken ticket" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(3)
    assert_equal 1, ticket.support_details.public_comments.count
    assert ticket.comment!("pong")
    assert_match "pong", ticket.support_details.last.content
    assert_match "sam (volunteer) wrote", ticket.support_details.last.info
    assert_equal 2, ticket.support_details.public_comments.count
  end
  test "volunteers can comment on spam ticket" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(2)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("looks like spam to me")
    assert_match "looks like spam to me", ticket.support_details.last.content
    assert_match "sam (volunteer) wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "volunteers can comment on posted ticket" do
    User.current_user = User.find_by_login("bofh")
    ticket = SupportTicket.find(12)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("done")
    assert_match "done", ticket.support_details.last.content
    assert_match "bofh (volunteer) wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "volunteers can comment on waiting ticket" do
    User.current_user = User.find_by_login("rodney")
    ticket = SupportTicket.find(4)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("gay marriage next?")
    assert_match "gay marriage next?", ticket.support_details.last.content
    assert_match "rodney (volunteer) wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "volunteers can comment on waiting_on_admin ticket" do
    User.current_user = User.find_by_login("bofh")
    ticket = SupportTicket.find(21)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("64 bytes from 127.0.0.1")
    assert_match "64 bytes from 127.0.0.1", ticket.support_details.last.content
    assert_match "bofh (volunteer) wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end
  test "volunteers can comment on closed ticket" do
    User.current_user = User.find_by_login("blair")
    ticket = SupportTicket.find(6)
    assert_equal 0, ticket.support_details.public_comments.count
    assert ticket.comment!("you're welcome")
    assert_match "you're welcome", ticket.support_details.last.content
    assert_match "blair (volunteer) wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.public_comments.count
  end

  # private volunteer comments
  test "volunteers can comment privately on unowned ticket" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(3)
    assert_equal 0, ticket.support_details.where(:private => true).count
    assert ticket.comment!("pong", true, nil, true)
    assert_match "pong", ticket.support_details.last.content
    assert_match "sam (volunteer) wrote [private]", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.where(:private => true).count
  end
  test "volunteers can comment privately on spam ticket" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(3)
    assert_equal 0, ticket.support_details.where(:private => true).count
    assert ticket.comment!("pong", true, nil, true)
    assert_match "pong", ticket.support_details.last.content
    assert_match "sam (volunteer) wrote [private]", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.where(:private => true).count
  end
  test "volunteers can comment privately on taken ticket" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(3)
    assert_equal 0, ticket.support_details.where(:private => true).count
    assert ticket.comment!("pong", true, nil, true)
    assert_match "pong", ticket.support_details.last.content
    assert_match "sam (volunteer) wrote [private]", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.where(:private => true).count
  end
  test "volunteers can comment privately on posted ticket" do
    User.current_user = User.find_by_login("bofh")
    ticket = SupportTicket.find(12)
    assert_equal 0, ticket.support_details.where(:private => true).count
    assert ticket.comment!("done", true, nil, true)
    assert_match "done", ticket.support_details.last.content
    assert_match "bofh (volunteer) wrote [private]", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.where(:private => true).count
  end
  test "volunteers can comment privately on waiting ticket" do
    User.current_user = User.find_by_login("rodney")
    ticket = SupportTicket.find(4)
    assert_equal 0, ticket.support_details.where(:private => true).count
    assert ticket.comment!("gay marriage next?", true, nil, true)
    assert_match "gay marriage next?", ticket.support_details.last.content
    assert_match "rodney (volunteer) wrote [private]", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.where(:private => true).count
  end
  test "volunteers can comment privately on waiting_on_admin ticket" do
    User.current_user = User.find_by_login("bofh")
    ticket = SupportTicket.find(21)
    assert_equal 2, ticket.support_details.where(:private => true).count
    assert ticket.comment!("Forever Is Just A Minute Away", true, nil, true)
    assert_match "Forever Is Just A Minute Away", ticket.support_details.last.content
    assert_match "bofh (volunteer) wrote [private]", ticket.support_details.last.info
    assert_equal 3, ticket.support_details.where(:private => true).count
  end
  test "volunteers can comment privately on closed ticket" do
    User.current_user = User.find_by_login("blair")
    ticket = SupportTicket.find(6)
    assert_equal 0, ticket.support_details.where(:private => true).count
    assert ticket.comment!("you're welcome", true, nil, true)
    assert_match "you're welcome", ticket.support_details.last.content
    assert_match "blair (volunteer) wrote [private]", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.where(:private => true).count
  end

end
