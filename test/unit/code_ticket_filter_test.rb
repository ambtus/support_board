require 'test_helper'

class CodeTicketTest < ActiveSupport::TestCase
  test "all" do
    assert_equal 7, CodeTicket.filter({:status => "all"}).count
  end
  test "unowned status" do
    assert_equal [1, 7], CodeTicket.filter({:status => "unowned"}).ids
  end
  test "taken status" do
    assert_equal [2], CodeTicket.filter({:status => "taken"}).ids
    assert_equal [2], CodeTicket.filter({:status => "taken", :owned_by_support_identity => "sam"}).ids
    assert_empty CodeTicket.filter({:status => "taken", :owned_by_support_identity => "blair"})
  end
  test "committed status" do
    assert_equal [5], CodeTicket.filter({:status => "committed"}).ids
  end
  test "staged status" do
    assert_equal [4], CodeTicket.filter({:status => "staged"}).ids
  end
  test "verified status" do
    assert_equal [3], CodeTicket.filter({:status => "verified"}).ids
  end
  test "closed status" do
    assert_equal [6], CodeTicket.filter({:status => "closed"}).ids
  end
  test "open status" do
    assert_equal 6, CodeTicket.filter({:status => "open"}).count
  end
  test "default open status" do
    assert_equal 6, CodeTicket.filter.count
  end
  test "unknown status" do
    assert_raise(TypeError) {CodeTicket.filter({:status => "unknown"})}
  end
  test "commented on" do
     assert_equal [4], CodeTicket.filter({:comments_by_support_identity => "john"}).ids
     assert_equal [4], CodeTicket.filter({:comments_by_support_identity => "john", :status => "staged"}).ids
     assert_equal [4], CodeTicket.filter({:comments_by_support_identity => "john", :owned_by_support_identity => "rodney"}).ids
     assert_empty CodeTicket.filter({:comments_by_support_identity => "john", :status => "committed"})
     assert_empty CodeTicket.filter({:comments_by_support_identity => "john", :owned_by_support_identity => "blair"})
     assert_equal [5], CodeTicket.filter({:comments_by_support_identity => "jim"}).ids
     assert_equal [5], CodeTicket.filter({:comments_by_support_identity => "jim", :status => "committed"}).ids
     assert_equal [5], CodeTicket.filter({:comments_by_support_identity => "jim", :owned_by_support_identity => "blair"}).ids
     assert_empty CodeTicket.filter({:comments_by_support_identity => "jim", :status => "staged"})
     assert_empty CodeTicket.filter({:comments_by_support_identity => "jim", :owned_by_support_identity => "rodney"})
  end
  test "owned by" do
    assert_equal [5], CodeTicket.filter(:owned_by_support_identity => "blair").ids
    assert_equal [2], CodeTicket.filter(:owned_by_support_identity => "sam").ids
    assert_equal [4], CodeTicket.filter(:owned_by_support_identity => "rodney").ids
    assert_equal [4, 6], CodeTicket.filter(:owned_by_support_identity => "rodney", :status => "all").ids
    assert_equal [3], CodeTicket.filter(:owned_by_support_identity => "bofh").ids
    assert_empty CodeTicket.filter(:owned_by_support_identity => "blair", :status => "closed")
    assert_empty CodeTicket.filter(:owned_by_support_identity => "bofh", :status => "taken")
  end
  test "watching" do
    assert_raise(SecurityError) {CodeTicket.filter({:watching => true})}
    User.current_user = User.find_by_login("sam")
    assert_equal [2], CodeTicket.filter({:watching => true, :status => "all"}).ids
    User.current_user = User.find_by_login("rodney")
    assert_equal [3, 4, 6], CodeTicket.filter({:watching => true, :status => "all"}).ids
    User.current_user = User.find_by_login("blair")
    assert_equal [5], CodeTicket.filter({:watching => true, :status => "all"}).ids
    User.current_user = User.find_by_login("bofh")
    assert_equal [3, 6], CodeTicket.filter({:watching => true, :status => "all"}).ids
  end
  test "sort" do
    User.current_user = User.find_by_login("rodney")
    assert_equal [3, 2, 7, 5, 1, 4], CodeTicket.filter({:by_vote => true }).map(&:id)
  end
end

