require 'test_helper'

class SupportTicketFilterTest < ActiveSupport::TestCase
  test "owned_by_user when bad username" do
    assert_raise(ActiveRecord::RecordNotFound) { SupportTicket.filter(:owned_by_user => "nobody") }
  end
  test "owned_by_user respects privacy and anonymity" do
    # tickets opened by john:
    # 4 & 13 are private & anonymous
    # 5 is private but not anonymous
    # 20 is anonymous but not private
    assert_empty SupportTicket.filter(:status => "all", :owned_by_user => "john")
    User.current_user = User.find_by_login("jim")
    assert_empty SupportTicket.filter(:status => "all", :owned_by_user => "john")
    User.current_user = User.find_by_login("john")
    assert_equal [4, 5, 13, 20], SupportTicket.filter(:status => "all", :owned_by_user => "john").ids
    User.current_user = User.find_by_login("sam")
    assert_equal [5], SupportTicket.filter(:status => "all", :owned_by_user => "john").ids
  end
  test "watching when guest" do
    assert_raise(ArgumentError) { SupportTicket.filter(:watching => true) }
  end
  test "watching when user" do
    User.current_user = User.find_by_login("jim")
    assert_equal [6, 7, 15, 16], SupportTicket.filter({:watching => true, :status => "all"}).ids
  end
  test "watching when volunteer" do
    User.current_user = User.find_by_login("sam")
    assert_equal [2, 3, 8, 14, 15, 18], SupportTicket.filter({:watching => true, :status => "all"}).ids
  end
  test "respect privacy" do
    assert_equal 13, SupportTicket.filter(:status => "all").count
    User.current_user = User.find_by_login("sam")
    assert_equal 22, SupportTicket.filter(:status => "all").count
  end
  test "comments_by_support_identity of an unknown user" do
    assert_raise(ActiveRecord::RecordNotFound) { SupportTicket.filter(:comments_by_support_identity => "nobody") }
  end
  test "comments_by_support_identity of a regular user" do
    assert_equal [3, 22], SupportTicket.filter(:comments_by_support_identity => "dean", :status => "all").ids
  end
  test "comments_by_support_identity of a volunteer by a non-volunteer" do
    # does not include private comments or system logs, but includes both official and non-official comments
    assert_equal [8, 12], SupportTicket.filter(:comments_by_support_identity => "sam", :status => "all").ids
  end
  test "comments_by_support_identity of a volunteer by a volunteer" do
    # includes private comments but not system logs
    User.current_user = User.find_by_login("blair")
    assert_equal [2, 8, 12, 14, 16, 21], SupportTicket.filter(:comments_by_support_identity => "sam", :status => "all").ids
  end
  test "owned_by_support_identity of an unknown user" do
    assert_raise(ActiveRecord::RecordNotFound) { SupportTicket.filter(:owned_by_support_identity => "nobody") }
  end
  test "owned_by_support_identity by guest respects privacy" do
    assert_equal [7, 10, 12], SupportTicket.filter(:owned_by_support_identity => "blair", :status => "all").ids
  end
  test "owned_by_support_identity by user respects privacy (even if they're yours)" do
    User.current_user = User.find_by_login("jim")
    assert_equal [7, 10, 12], SupportTicket.filter(:owned_by_support_identity => "blair", :status => "all").ids
  end
  test "owned_by_support_identity by volunteer shows private tickets" do
    User.current_user = User.find_by_login("sam")
    assert_equal [6, 7, 10, 11, 12], SupportTicket.filter(:owned_by_support_identity => "blair", :status => "all").ids
  end
  test "unowned status" do
    assert_equal [1, 8, 20], SupportTicket.filter({:status => "unowned"}).ids
    User.current_user = User.find_by_login("blair")
    assert_equal [1, 8, 16, 20], SupportTicket.filter({:status => "unowned"}).ids
  end
  test "taken status" do
    assert_equal [3, 9], SupportTicket.filter({:status => "taken"}).ids
  end
  test "waiting_on_admin status" do
    assert_equal [21], SupportTicket.filter({:status => "waiting_on_admin"}).ids
    User.current_user = User.find_by_login("sam")
    assert_equal [17, 21], SupportTicket.filter({:status => "waiting_on_admin"}).ids
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
    User.current_user = User.find_by_login("john")
    assert_equal [7], SupportTicket.filter({:status => "waiting"}).ids
    User.current_user = User.find_by_login("sam")
    assert_equal [4, 7], SupportTicket.filter({:status => "waiting"}).ids
  end
  test "spam status" do
    assert_empty SupportTicket.filter({:status => "spam"})
    User.current_user = User.find_by_login("sam")
    assert_equal [2], SupportTicket.filter({:status => "spam"}).ids
  end
  test "closed status" do
    assert_equal [18, 19, 22], SupportTicket.filter({:status => "closed"}).ids
    User.current_user = User.find_by_login("sam")
    assert_equal [5, 6, 18, 19, 22], SupportTicket.filter({:status => "closed"}).ids
  end
  # not spam or closed by a faq or posted as a comment
  test "not closed" do
    assert_equal 7, SupportTicket.filter.count
    assert_equal 7, SupportTicket.filter(:status => "open").count
    User.current_user = User.find_by_login("sam")
    assert_equal 10, SupportTicket.filter.count
    assert_equal 10, SupportTicket.filter(:status => "open").count
  end
  test "unknown status" do
    assert_raise(ArgumentError) {SupportTicket.filter({:status => "unknown"})}
  end
  test "all" do
    assert_equal 13, SupportTicket.filter({:status => "all"}).count
    User.current_user = User.find_by_login("sam")
    assert_equal 22, SupportTicket.filter({:status => "all"}).count
  end
  # TODO tests for sorting
  # combinations
  test "owned_by_support_identity shows your anonymous and private tickets if you filter for your tickets" do
    User.current_user = User.find_by_login("jim")
    assert_equal [6, 7], SupportTicket.filter(:owned_by_support_identity => "blair",
                                              :status => "all", :owned_by_user => "jim").ids
  end
  test "owned_by_support_identity respects anonymity when filtered by user" do
    User.current_user = User.find_by_login("bofh")
    assert_equal [], SupportTicket.filter(:owned_by_support_identity => "blair",
                                          :status => "all", :owned_by_user => "jim").ids
  end
  test "owned_by_support_identity shows your anonymous and private tickets if you filter for tickets you are watching" do
    User.current_user = User.find_by_login("jim")
    assert_equal [6, 7], SupportTicket.filter(:owned_by_support_identity => "blair",
                                              :status => "all", :watching => true).ids
  end
  test "filtered by status shows our anonymous and private tickets if you filter for tickets you are watching" do
    User.current_user = User.find_by_login("john")
    assert_equal [4], SupportTicket.filter({:status => "waiting", :watching => true}).ids
  end
  test "filtered by status shows our anonymous and private tickets if you filter for tickets you opened" do
    User.current_user = User.find_by_login("john")
    assert_equal [4], SupportTicket.filter({:status => "waiting", :owned_by_user => "john"}).ids
  end
  test "filtered by status respects anonymity when filtered by user" do
    User.current_user = User.find_by_login("bofh")
    assert_equal [], SupportTicket.filter({:status => "waiting", :owned_by_user => "john"}).ids
  end
end

