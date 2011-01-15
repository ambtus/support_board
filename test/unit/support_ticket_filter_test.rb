require 'test_helper'

class SupportTicketTest < ActiveSupport::TestCase
  test "all" do
    assert_equal 8, SupportTicket.filter({:status => "all"}).count
    User.current_user = User.find_by_login("sam")
    assert_equal 16, SupportTicket.filter({:status => "all"}).count
  end
  test "unowned status" do
    assert_equal [1, 8], SupportTicket.filter({:status => "unowned"}).ids
  end
  test "taken status" do
    assert_equal [3, 9], SupportTicket.filter({:status => "taken"}).ids
    assert_equal [3], SupportTicket.filter({:status => "taken", :owned_by_user => "dean"}).ids
    User.current_user = User.find_by_login("dean")
    assert_equal [3, 9], SupportTicket.filter({:status => "taken", :owned_by_user => "dean"}).ids
    User.current_user = User.find_by_login("sam")
    assert_equal [3], SupportTicket.filter({:status => "taken", :owned_by_user => "dean"}).ids
  end
  test "admin status" do
    assert_empty SupportTicket.filter({:status => "waiting_on_admin"})
  end
  test "posted status" do
    assert_equal [10, 12, 14], SupportTicket.filter({:status => "posted"}).ids
    User.current_user = User.find_by_login("newbie")
    assert_equal [10, 12, 14], SupportTicket.filter({:status => "posted"}).ids
    User.current_user = User.find_by_login("sam")
    assert_equal [10, 11, 12, 13, 14, 15], SupportTicket.filter({:status => "posted"}).ids
  end
  test "waiting status" do
    assert_equal [7], SupportTicket.filter({:status => "waiting"}).ids
    User.current_user = User.find_by_login("sam")
    assert_equal [4, 7], SupportTicket.filter({:status => "waiting"}).ids
    User.current_user = User.find_by_login("john")
    assert_equal [4], SupportTicket.filter({:status => "waiting", :owned_by_user => "john"}).ids
    User.current_user = User.find_by_login("jim")
    assert_equal [7], SupportTicket.filter({:status => "waiting", :owned_by_user => "jim"}).ids
    User.current_user = User.find_by_login("sam")
    assert_empty SupportTicket.filter({:status => "waiting", :owned_by_user => "john"})
    assert_empty SupportTicket.filter({:status => "waiting", :owned_by_user => "jim"})
  end
  test "spam status" do
    assert_empty SupportTicket.filter({:status => "spam"})
    User.current_user = User.find_by_login("sam")
    assert_equal [2], SupportTicket.filter({:status => "spam"}).ids
  end
  test "closed status" do
    User.current_user = User.find_by_login("john")
    assert_empty SupportTicket.filter({:status => "closed"})
    assert_equal [5], SupportTicket.filter({:status => "closed", :owned_by_user => "john" }).ids
    assert_empty SupportTicket.filter({:status => "closed", :owned_by_user => "jim" })

    User.current_user = User.find_by_login("jim")
    assert_empty SupportTicket.filter({:status => "closed"})
    assert_empty SupportTicket.filter({:status => "closed", :owned_by_user => "john" })
    assert_equal [6], SupportTicket.filter({:status => "closed", :owned_by_user => "jim" }).ids

    User.current_user = User.find_by_login("sam")
    assert_equal [5, 6], SupportTicket.filter({:status => "closed"}).ids
    assert_equal [5], SupportTicket.filter({:status => "closed", :owned_by_user => "john" }).ids
    assert_empty SupportTicket.filter({:status => "closed", :owned_by_user => "jim" })
  end
  # not spam or closed by a faq or posted as a comment
  test "not closed" do
    assert_equal 5, SupportTicket.filter.count
    User.current_user = User.find_by_login("sam")
    assert_equal 7, SupportTicket.filter.count
  end
  test "unknown status" do
    assert_raise(TypeError) {SupportTicket.filter({:status => "unknown"})}
  end
  test "commented on" do
     assert_equal [3], SupportTicket.filter({:comments_by_support_identity => "dean"}).ids
     assert_equal [3], SupportTicket.filter({:comments_by_support_identity => "dean", :owned_by_support_identity => "sam"}).ids
     assert_equal [3], SupportTicket.filter({:comments_by_support_identity => "dean", :status => "taken"}).ids
     assert_empty SupportTicket.filter({:comments_by_support_identity => "dean", :status => "waiting"})
     assert_empty SupportTicket.filter({:comments_by_support_identity => "dean", :owned_by_support_identity => "blair"})
     assert_equal [8], SupportTicket.filter({:comments_by_support_identity => "sam"}).ids
     assert_empty SupportTicket.filter({:comments_by_support_identity => "sam", :status => "closed"})
     assert_empty SupportTicket.filter({:comments_by_support_identity => "bofh"})
  end
  test "owned by" do
    assert_equal [7], SupportTicket.filter(:owned_by_support_identity => "blair").ids
    assert_equal [3], SupportTicket.filter(:owned_by_support_identity => "sam").ids
    assert_empty SupportTicket.filter(:owned_by_support_identity => "rodney").ids
    assert_equal [9], SupportTicket.filter(:owned_by_support_identity => "bofh").ids
    assert_empty SupportTicket.filter(:owned_by_support_identity => "blair", :status => "closed")
    assert_empty SupportTicket.filter(:owned_by_support_identity => "bofh", :status => "waiting")
    User.current_user = User.find_by_login("blair")
    assert_equal [6], SupportTicket.filter(:owned_by_support_identity => "blair", :status => "closed").ids
    assert_equal [2, 3, 15], SupportTicket.filter(:owned_by_support_identity => "sam", :status => "all").ids
    assert_equal [4], SupportTicket.filter(:owned_by_support_identity => "rodney", :status => "waiting").ids
  end
  test "watching" do
    assert_raise(SecurityError) {SupportTicket.filter({:watching => true})}
    User.current_user = User.find_by_login("jim")
    assert_equal [7, 16], SupportTicket.filter({:watching => true}).ids
    assert_equal [6, 7, 15, 16], SupportTicket.filter({:watching => true, :status => "all"}).ids
    assert_equal [7], SupportTicket.filter({:watching => true, :status => "waiting", :owned_by_user => "jim"}).ids
    assert_empty SupportTicket.filter({:watching => true, :status => "waiting_on_admin"})
    User.current_user = User.find_by_login("dean")
    assert_equal [3, 9], SupportTicket.filter({:watching => "dean"}).ids
    assert_equal [3], SupportTicket.filter({:watching => "dean", :comments_by_support_identity => "dean"}).ids
    User.current_user = User.find_by_login("sam")
    assert_equal [3, 8], SupportTicket.filter({:watching => true}).ids
    assert_equal [3], SupportTicket.filter({:watching => true, :owned_by_user => "dean"}).ids
    assert_equal [8], SupportTicket.filter({:watching => true, :owned_by_user => "sam"}).ids
  end
end

