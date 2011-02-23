require 'test_helper'

class SupportTicketCommentTest < ActiveSupport::TestCase
  test "visible_support_details" do
    ticket = SupportTicket.find(2)
    assert_equal 1, ticket.visible_support_details.size
    User.current_user = User.find_by_login("jim")
    assert_equal 1, ticket.visible_support_details.size
    User.current_user = User.find_by_login("sam")
    assert_equal 4, ticket.visible_support_details.size
  end
  test "system logs" do
    assert_equal %Q{unowned -> spam}, SupportTicket.find(2).support_details.system_log.last.content
    assert_equal %Q{unowned -> taken}, SupportTicket.find(3).support_details.system_log.last.content
    assert_equal %Q{unowned -> waiting (3)}, SupportTicket.find(4).support_details.system_log.last.content
    assert_equal %Q{unowned -> closed (4)}, SupportTicket.find(5).support_details.system_log.last.content
    assert_equal %Q{unowned -> closed (5)}, SupportTicket.find(6).support_details.system_log.last.content
  end

  # guest comments
  test "not logged in can't comment on unowned guest ticket if authentication code doesn't match" do
    ticket = SupportTicket.find(1)
    assert_raise(SecurityError) { ticket.guest_owner_comment!("something", "") }
    assert_raise(SecurityError) { ticket.guest_owner_comment!("something", SecureRandom.hex(9)) }
    assert_raise(SecurityError) { ticket.guest_owner_comment!("something", ticket.authentication_code + "a") }
  end
  test "not logged in can't comment on unowned user ticket" do
    ticket = SupportTicket.find(8)
    assert_raise(SecurityError) { ticket.guest_owner_comment!("something", "") }
    assert_raise(SecurityError) { ticket.guest_owner_comment!("something", SecureRandom.hex(9)) }
  end
  test "not logged in can comment (anonymous) on unowned guest ticket if authentication does match" do
    ticket = SupportTicket.find(1)
    assert_equal 0, ticket.support_details.written_comments.count
    assert ticket.guest_owner_comment!("I have something to say", ticket.authentication_code)
    assert_match "I have something to say", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.written_comments.count
  end
  test "not logged in can comment (anonymous) on spam guest ticket if authentication code matches" do
    ticket = SupportTicket.find(2)
    assert_equal 0, ticket.support_details.written_comments.visible_to_all.count
    assert ticket.guest_owner_comment!("This is not spam!", ticket.authentication_code)
    assert_match "This is not spam!", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.written_comments.visible_to_all.count
  end
  test "not logged in can comment (anonymous) on posted guest ticket if authentication code matches" do
    ticket = SupportTicket.find(11)
    assert_equal 0, ticket.support_details.written_comments.count
    assert ticket.guest_owner_comment!("please take this off the comments page",ticket.authentication_code)
    assert_match "please take this off the comments page", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.written_comments.count
  end
  test "not logged in can comment (anonymous) on waiting guest ticket if authentication code matches" do
    ticket = SupportTicket.find(18)
    assert_equal 0, ticket.support_details.written_comments.count
    assert ticket.guest_owner_comment!("looks fine in firefox", ticket.authentication_code)
    assert_match "looks fine in firefox", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.written_comments.count
  end
  test "not logged in can comment (anonymous) on waiting_on_admin guest ticket if authentication code matches" do
    ticket = SupportTicket.find(17)
    assert_equal 1, ticket.support_details.written_comments.count
    assert ticket.guest_owner_comment!("my old email was sad@ao3.org", ticket.authentication_code)
    assert_match "my old email was sad@ao3.org", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 2, ticket.support_details.written_comments.count
  end
  test "not logged in can comment (anonymous) on closed guest ticket if authentication code matches" do
    ticket = SupportTicket.find(19)
    assert_equal 0, ticket.support_details.written_comments.count
    assert ticket.guest_owner_comment!("i meant the ff importer is down", ticket.authentication_code)
    assert_match "i meant the ff importer is down", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.written_comments.count
  end

  # user comments on tickets not their own
  test "any user can comment (not anonymous) on open tickets" do
    ticket = SupportTicket.find(20)
    assert_equal 0, ticket.support_details.written_comments.count
    User.current_user = User.find_by_login("dean")
    assert ticket.user_comment!("I have something to add")
    assert_equal "I have something to add", ticket.support_details.last.content
    assert_match "dean wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.written_comments.count
  end
  test "if the user isn't official, doesn't get the volunteer designation even if requested" do
    ticket = SupportTicket.find(20)
    assert_equal 0, ticket.support_details.written_comments.count
    User.current_user = User.find_by_login("dean")
    assert ticket.user_comment!("I have something to add", true)
    assert_equal "I have something to add", ticket.support_details.last.content
    assert_match "dean wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.written_comments.count
  end
  test "users can't comment on private tickets even if unowned" do
    ticket = SupportTicket.find(16)
    User.current_user = User.find_by_login("dean")
    assert_raise(SecurityError) { ticket.user_comment!("user on private ticket") }
  end
  test "users can comment on private tickets if unowned and theirs" do
    ticket = SupportTicket.find(16)
    User.current_user = User.find_by_login("jim")
    assert ticket.user_comment!("owner on private ticket")
    assert_match "ticket owner wrote", ticket.support_details.last.info
  end
  test "users can only comment on unowned tickets" do
    User.current_user = User.find_by_login("newbie")
    ticket = SupportTicket.find(2)
    assert_raise(SecurityError) { ticket.user_comment!("user on spam ticket") }
    ticket = SupportTicket.find(3)
    assert_raise(SecurityError) { ticket.user_comment!("user on taken ticket") }
    ticket = SupportTicket.find(14)
    assert_raise(SecurityError) { ticket.user_comment!("user on posted ticket") }
    ticket = SupportTicket.find(7)
    assert_raise(SecurityError) { ticket.user_comment!("user on waiting ticket") }
    ticket = SupportTicket.find(17)
    assert_raise(SecurityError) { ticket.user_comment!("user on waiting_on_admin ticket") }
    ticket = SupportTicket.find(19)
    assert_raise(SecurityError) { ticket.user_comment!("user on closed ticket") }
  end

  # user comments on their own tickets
  test "owner comments are anonymous if the ticket is anonymous" do
    ticket = SupportTicket.find(20)
    assert_equal 0, ticket.support_details.written_comments.count
    User.current_user = User.find_by_login("john")
    assert ticket.user_comment!("I have something to add")
    assert_equal "I have something to add", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.written_comments.count
  end
  test "comment anonymity changes when ticket anonymity changes" do
    john = User.find_by_login("john")
    ticket = SupportTicket.find(5)
    assert !ticket.anonymous?
    assert_equal john, ticket.user
    assert_equal 0, ticket.support_details.written_comments.count
    User.current_user = john
    assert ticket.user_comment!("something to say")
    assert_equal 1, ticket.support_details.written_comments.count
    assert_equal "something to say", ticket.support_details.written_comments.first.content
    assert_match "john wrote", ticket.support_details.written_comments.first.info
    assert ticket.hide_username!
    assert ticket.anonymous?
    assert_match "ticket owner wrote", ticket.support_details.written_comments.first.reload.info
  end
  test "users can comment on taken ticket if it's theirs" do
    User.current_user = User.find_by_login("dean")
    ticket = SupportTicket.find(3)
    assert_equal 1, ticket.support_details.written_comments.count
    assert ticket.user_comment!("ping")
    assert_match "ping", ticket.support_details.last.content
    assert_match "dean wrote", ticket.support_details.last.info
    assert_equal 2, ticket.support_details.written_comments.count
  end
  test "users can comment on posted ticket if it's theirs" do
    User.current_user = User.find_by_login("newbie")
    ticket = SupportTicket.find(12)
    assert_equal 1, ticket.support_details.written_comments.count
    assert ticket.user_comment!("take this off the comments page")
    assert_match "take this off the comments page", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 2, ticket.support_details.written_comments.count
  end
  test "users can comment on waiting ticket if it's theirs" do
    User.current_user = User.find_by_login("john")
    ticket = SupportTicket.find(4)
    assert_equal 1, ticket.support_details.written_comments.count
    assert ticket.user_comment!("none too soon")
    assert_match "none too soon", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 2, ticket.support_details.written_comments.count
  end
  test "users can comment on waiting_on_admin ticket if it's theirs" do
    User.current_user = User.find_by_login("dean")
    ticket = SupportTicket.find(21)
    assert_equal 0, ticket.support_details.written_comments.visible_to_all.count
    assert ticket.user_comment!("ping")
    assert_match "ping", ticket.support_details.last.content
    assert_match "dean wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.written_comments.visible_to_all.count
  end
  test "users can comment on closed ticket if it's theirs" do
    User.current_user = User.find_by_login("jim")
    ticket = SupportTicket.find(6)
    assert_equal 0, ticket.support_details.written_comments.count
    assert ticket.user_comment!("thanks")
    assert_match "thanks", ticket.support_details.last.content
    assert_match "ticket owner wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.written_comments.count
  end

  # unofficial volunteer comments
  test "volunteers who comment on their own user tickets unofficially respects anonymity" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(8)
    assert !ticket.anonymous?
    assert_equal 1, ticket.support_details.count
    assert_match "sam wrote", ticket.support_details.first.info
    assert ticket.user_comment!("i'm warning you", "official")
    assert_match "sam (volunteer) wrote", ticket.support_details[1].reload.info
    assert_equal 2, ticket.support_details.count
    assert ticket.hide_username!
    assert_equal 3, ticket.support_details.count
    assert_equal "don't make me come looking for you!", ticket.support_details[0].content
    assert_match "ticket owner wrote", ticket.support_details[0].reload.info
    assert_match "i'm warning you", ticket.support_details[1].content
    assert_match "sam (volunteer) wrote", ticket.support_details[1].reload.info
    assert_match "hide username", ticket.support_details[2].content
    assert_match "ticket owner", ticket.support_details[2].reload.info
    assert ticket.show_username!
    assert_match "sam", ticket.support_details[0].reload.info
    assert_match "sam (volunteer)", ticket.support_details[1].reload.info
    assert_match "sam", ticket.support_details[2].reload.info
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
    assert_equal 0, ticket.support_details.written_comments.count
    assert ticket.user_comment!("something random", false)
    assert_match "something random", ticket.support_details.last.content
    assert_match "sam wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.written_comments.count
  end
  test "volunteers can comment on unowned user tickets unofficially" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(20)
    assert_equal 0, ticket.support_details.written_comments.count
    assert ticket.user_comment!("hunting is my game", false)
    assert_match "hunting is my game", ticket.support_details.last.content
    assert_match "sam wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.written_comments.count
  end
  test "volunteers can't comment on tickets unofficially unless they're unowned" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(2)
    assert_raise(SecurityError) { ticket.user_comment!("spam ticket", "unofficial") }
    ticket = SupportTicket.find(3)
    assert_raise(SecurityError) { ticket.user_comment!("taken ticket", "unofficial") }
    ticket = SupportTicket.find(14)
    assert_raise(SecurityError) { ticket.user_comment!("posted ticket", "unofficial") }
    ticket = SupportTicket.find(7)
    assert_raise(SecurityError) { ticket.user_comment!("waiting ticket", "unofficial") }
    ticket = SupportTicket.find(17)
    assert_raise(SecurityError) { ticket.user_comment!("waiting_on_admin ticket", "unofficial") }
    ticket = SupportTicket.find(19)
    assert_raise(SecurityError) { ticket.user_comment!("closed ticket", "unofficial") }
  end

  # official volunteer comments
  test "volunteers commenting officially are not anonymous even if it's their own anonymous ticket" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(8)
    assert_equal 1, ticket.support_details.written_comments.count
    assert ticket.user_comment!("i'm warning you", "official")
    assert_match "i'm warning you", ticket.support_details.last.content
    assert_match "sam (volunteer) wrote", ticket.support_details.last.info
    assert_equal 2, ticket.support_details.written_comments.count
  end
  test "volunteers can comment on taken ticket" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(3)
    assert_equal 1, ticket.support_details.written_comments.count
    assert ticket.user_comment!("ping")
    assert_match "ping", ticket.support_details.last.content
    assert_match "sam (volunteer) wrote", ticket.support_details.last.info
    assert_equal 2, ticket.support_details.written_comments.count
  end
  test "volunteers can comment on spam ticket" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(2)
    assert_equal 3, ticket.support_details.written_comments.count
    assert ticket.user_comment!("looks like spam to me")
    assert_match "looks like spam to me", ticket.support_details.last.content
    assert_match "sam (volunteer) wrote", ticket.support_details.last.info
    assert_equal 4, ticket.support_details.written_comments.count
  end
  test "volunteers can comment on posted ticket" do
    User.current_user = User.find_by_login("sidra")
    ticket = SupportTicket.find(12)
    assert_equal 1, ticket.support_details.written_comments.count
    assert ticket.user_comment!(";)")
    assert_match ";)", ticket.support_details.last.content
    assert_match "sidra (volunteer) wrote", ticket.support_details.last.info
    assert_equal 2, ticket.support_details.written_comments.count
  end
  test "volunteers can comment on waiting ticket" do
    User.current_user = User.find_by_login("rodney")
    ticket = SupportTicket.find(4)
    assert_equal 1, ticket.support_details.written_comments.count
    assert ticket.user_comment!("gay marriage next?")
    assert_match "gay marriage next?", ticket.support_details.last.content
    assert_match "rodney (volunteer) wrote", ticket.support_details.last.info
    assert_equal 2, ticket.support_details.written_comments.count
  end
  test "volunteers can comment on waiting_on_admin ticket" do
    User.current_user = User.find_by_login("sidra")
    ticket = SupportTicket.find(21)
    assert_equal 2, ticket.support_details.written_comments.count
    assert ticket.user_comment!("64 bytes from 127.0.0.1")
    assert_match "64 bytes from 127.0.0.1", ticket.support_details.last.content
    assert_match "sidra (volunteer) wrote", ticket.support_details.last.info
    assert_equal 3, ticket.support_details.written_comments.count
  end
  test "volunteers can comment on closed ticket" do
    User.current_user = User.find_by_login("blair")
    ticket = SupportTicket.find(6)
    assert_equal 0, ticket.support_details.written_comments.count
    assert ticket.user_comment!("you're welcome")
    assert_match "you're welcome", ticket.support_details.last.content
    assert_match "blair (volunteer) wrote", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.written_comments.count
  end

  # private volunteer comments
  test "volunteers can comment privately on unowned ticket" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(3)
    assert_equal 0, ticket.support_details.where(:private => true).count
    assert ticket.user_comment!("ping", "private")
    assert_match "ping", ticket.support_details.last.content
    assert_match "sam (volunteer) wrote [private]", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.where(:private => true).count
  end
  test "volunteers can comment privately on spam ticket" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(3)
    assert_equal 0, ticket.support_details.where(:private => true).count
    assert ticket.user_comment!("ping", "private")
    assert_match "ping", ticket.support_details.last.content
    assert_match "sam (volunteer) wrote [private]", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.where(:private => true).count
  end
  test "volunteers can comment privately on taken ticket" do
    User.current_user = User.find_by_login("sam")
    ticket = SupportTicket.find(3)
    assert_equal 0, ticket.support_details.where(:private => true).count
    assert ticket.user_comment!("ping", "private")
    assert_match "ping", ticket.support_details.last.content
    assert_match "sam (volunteer) wrote [private]", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.where(:private => true).count
  end
  test "volunteers can comment privately on posted ticket" do
    User.current_user = User.find_by_login("sidra")
    ticket = SupportTicket.find(12)
    assert_equal 0, ticket.support_details.where(:private => true).count
    assert ticket.user_comment!("foo bar", "private")
    assert_match "foo bar", ticket.support_details.last.content
    assert_match "sidra (volunteer) wrote [private]", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.where(:private => true).count
  end
  test "volunteers can comment privately on waiting ticket" do
    User.current_user = User.find_by_login("rodney")
    ticket = SupportTicket.find(4)
    assert_equal 0, ticket.support_details.where(:private => true).count
    assert ticket.user_comment!("gay marriage next?", "private")
    assert_match "gay marriage next?", ticket.support_details.last.content
    assert_match "rodney (volunteer) wrote [private]", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.where(:private => true).count
  end
  test "volunteers can comment privately on waiting_on_admin ticket" do
    User.current_user = User.find_by_login("sidra")
    ticket = SupportTicket.find(21)
    assert_equal 2, ticket.support_details.where(:private => true).count
    assert ticket.user_comment!("Forever Is Just A Minute Away", "private")
    assert_match "Forever Is Just A Minute Away", ticket.support_details.last.content
    assert_match "sidra (volunteer) wrote [private]", ticket.support_details.last.info
    assert_equal 3, ticket.support_details.where(:private => true).count
  end
  test "volunteers can comment privately on closed ticket" do
    User.current_user = User.find_by_login("blair")
    ticket = SupportTicket.find(6)
    assert_equal 0, ticket.support_details.where(:private => true).count
    assert ticket.user_comment!("anyone know who this guy is?", "private")
    assert_match "anyone know who this guy is?", ticket.support_details.last.content
    assert_match "blair (volunteer) wrote [private]", ticket.support_details.last.info
    assert_equal 1, ticket.support_details.where(:private => true).count
  end

end
