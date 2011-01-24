require 'test_helper'

class CodeTicketFilterTest < ActiveSupport::TestCase
  test "watching when guest" do
    assert_raise(SecurityError) { CodeTicket.filter(:watching => true) }
  end
  test "watching when user" do
    User.current_user = User.find_by_login("jim")
    assert_equal [5], CodeTicket.filter({:watching => true, :status => "all"}).ids
  end
  test "watching when volunteer" do
    User.current_user = User.find_by_login("sam")
    assert_equal [7, 2, 1], CodeTicket.filter({:watching => true, :status => "all"}).ids
  end
  test "comments_by_support_identity of an unknown user" do
    assert_raise(ActiveRecord::RecordNotFound) { CodeTicket.filter(:comments_by_support_identity => "nobody") }
  end
  test "comments_by_support_identity of a regular user" do
    assert_equal [4], CodeTicket.filter(:comments_by_support_identity => "john", :status => "all").ids
  end
  test "comments_by_support_identity of a volunteer by a non-volunteer" do
    # does not include private comments or system logs, but includes both official and non-official comments
    assert_equal [6], CodeTicket.filter(:comments_by_support_identity => "sidra", :status => "all").ids
  end
  test "comments_by_support_identity of a volunteer by a volunteer" do
    # includes private comments but not system logs
    User.current_user = User.find_by_login("blair")
    assert_equal [6, 4], CodeTicket.filter(:comments_by_support_identity => "sidra", :status => "all").ids
  end
  test "owned_by_support_identity" do
    assert_equal [5], CodeTicket.filter(:owned_by_support_identity => "blair").ids
    assert_equal [2, 8], CodeTicket.filter(:owned_by_support_identity => "sam", :status => "all", :sort_by => "oldest first").ids
    assert_equal [4], CodeTicket.filter(:owned_by_support_identity => "rodney").ids
    assert_equal [4, 6], CodeTicket.filter(:owned_by_support_identity => "rodney", :status => "all", :sort_by => "oldest first").ids
    assert_equal [3], CodeTicket.filter(:owned_by_support_identity => "sidra").ids
  end
  test "closed_in_release unknown release" do
    assert_raise(ActiveRecord::RecordNotFound) { CodeTicket.filter(:closed_in_release => 17) }
  end
  test "closed_in_release" do
    assert_equal [6], CodeTicket.filter(:closed_in_release => 1).ids
    assert_equal [7], CodeTicket.filter(:closed_in_release => 2).ids
  end
  test "closed_in_release ignore status" do
    assert_equal [6], CodeTicket.filter(:closed_in_release => 1, :status => "taken").ids
  end
  test "unowned status" do
    assert_equal [1], CodeTicket.filter({:status => "unowned"}).ids
  end
  test "taken status" do
    assert_equal [2], CodeTicket.filter({:status => "taken"}).ids
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
    assert_equal [6, 7, 8], CodeTicket.filter({:status => "closed", :sort_by => "oldest first"}).ids
  end
  test "all" do
    assert_equal 8, CodeTicket.filter({:status => "all"}).count
  end
  test "open status" do
    assert_equal 5, CodeTicket.filter({:status => "open"}).count
  end
  test "open status is default" do
    assert_equal 5, CodeTicket.filter.count
  end
  test "unknown status" do
    assert_raise(TypeError) {CodeTicket.filter({:status => "unknown"})}
  end
  test "sort_by recently updated" do
    assert_equal [8, 2], CodeTicket.filter({:sort_by => "recently updated", :owned_by_support_identity => "sam", :status => "all"}).ids
    User.current_user = User.find_by_login("sam")
    CodeTicket.find(2).commit!(CodeCommit.find(1))
    assert_equal [2, 8], CodeTicket.filter({:sort_by => "recently updated", :owned_by_support_identity => "sam", :status => "all"}).ids
  end
  test "sort_by least recently updated" do
    User.current_user = User.find_by_login("rodney")
    assert_equal [1, 2, 3, 4, 5], CodeTicket.filter({:sort_by => "least recently updated"}).ids
    User.current_user = User.find_by_login("rodney")
    CodeTicket.first.take!
    assert_equal [2, 3, 4, 5, 1], CodeTicket.filter({:sort_by => "least recently updated"}).ids
  end
  test "sort_by oldest first" do
    User.current_user = User.find_by_login("rodney")
    assert_equal [1, 2, 3, 4, 5], CodeTicket.filter({:sort_by => "oldest first"}).ids
  end
  test "sort_by highest vote" do
    assert_equal [3, 2, 5, 1, 4], CodeTicket.filter({:sort_by => "highest vote"}).map(&:id) # can't use ids
  end
  test "sort_by newest" do
    assert_equal [5, 4, 3, 2, 1], CodeTicket.filter({:sort_by => "newest"}).ids
  end
  test "sort_by unknown" do
    assert_raise(TypeError) { CodeTicket.filter({:sort_by => "oldest"}) }
  end
  test "sort_by default is newest" do
    assert_equal [5, 4, 3, 2, 1], CodeTicket.filter.ids
  end
  test "a few combinations" do
    assert_equal [7], CodeTicket.filter(:owned_by_support_identity => "blair", :status => "closed").ids
    assert_empty CodeTicket.filter(:owned_by_support_identity => "sidra", :status => "taken")
    assert_equal [2], CodeTicket.filter({:status => "taken", :owned_by_support_identity => "sam"}).ids
    assert_equal [7, 6, 8], CodeTicket.filter({:sort_by => "highest vote", :status => "closed"}).map(&:id) # can't use ids
  end
end

