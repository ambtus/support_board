require 'test_helper'

class CodeCommitTest < ActiveSupport::TestCase
  test "validate author" do
    assert_raise(ActiveRecord::RecordInvalid) { CodeCommit.create! }
    assert CodeCommit.create!(:author => "someone")
  end
  test "name" do
    assert_equal "Code Commit #1", CodeCommit.find(1).name
  end
  test "info" do
    assert_match "] sam (unmatched)", CodeCommit.find(1).info
    assert_match "] rodney (verified)", CodeCommit.find(2).info
    assert_match "] rodney (staged)", CodeCommit.find(3).info
    assert_match "] blair (matched)", CodeCommit.find(4).info
    assert_match "] bofh (deployed)", CodeCommit.find(5).info
    assert_match "] rodney (deployed)", CodeCommit.find(6).info
  end
  test "support identity existing" do
    commit = CodeCommit.create(:author => "rodney")
    assert_equal commit.support_identity_id, SupportIdentity.find_by_name("rodney").id
  end
  test "support identity created" do
    assert_nil SupportIdentity.find_by_name("new coder")
    assert commit = CodeCommit.create(:author => "new coder")
    assert SupportIdentity.find_by_name("new coder")
    assert_equal "new coder", commit.support_identity.name
  end
  test "no match" do
    commit = CodeCommit.create(:author => "sam")
    assert commit.unmatched?
  end
  test "auto match" do
    assert ticket = CodeTicket.find(2)
    assert ticket.taken?
    assert_equal "sam", ticket.support_identity.name
    commit = CodeCommit.create(:author => "blair", :message => "closes issue 2")
    assert commit.reload.matched?
    assert_equal ticket, commit.code_ticket
    assert_equal commit, ticket.code_commits.first
    assert ticket.reload.committed?
    assert_equal "blair", ticket.support_identity.name
  end
  test "manual match" do
    assert ticket = CodeTicket.find(1)
    assert ticket.unowned?
    commit = CodeCommit.find(1)
    assert commit.unmatched?
    User.current_user = User.find_by_login("bofh")
    assert ticket.commit!(commit.id)
    assert commit.reload.matched?
    assert_equal ticket, commit.code_ticket
    assert_equal commit, ticket.code_commits.first
    assert ticket.committed?
  end
  test "filter by nonexistent owned_by_support_identity" do
    assert_raise(ActiveRecord::RecordNotFound) { CodeCommit.filter(:owned_by_support_identity => "nobody") }
  end
  test "filter by owned_by_support_identity" do
    assert_equal [1], CodeCommit.filter(:owned_by_support_identity => "sam", :status => "all").ids
    assert_equal [4], CodeCommit.filter(:owned_by_support_identity => "blair", :status => "all").ids
    assert_equal [2, 3, 6], CodeCommit.filter(:owned_by_support_identity => "rodney", :status => "all").ids
    assert_equal [5], CodeCommit.filter(:owned_by_support_identity => "bofh", :status => "all").ids
  end
  test "filter by nonexistent status" do
    assert_raise(TypeError) { CodeCommit.filter(:status => "unknown") }
  end
  test "filter default is unmatched" do
    assert_equal [1], CodeCommit.filter.ids
  end
  test "filter by status" do
    assert_equal 6, CodeCommit.filter(:status => "all").count
    assert_equal [1], CodeCommit.filter(:status => "unmatched").ids
    assert_equal [2], CodeCommit.filter(:status => "verified").ids
    assert_equal [3], CodeCommit.filter(:status => "staged").ids
    assert_equal [4], CodeCommit.filter(:status => "matched").ids
    assert_equal [5, 6], CodeCommit.filter(:status => "deployed").ids
    assert_equal [1], CodeCommit.filter.ids
  end
  test "filter by both" do
    assert_equal [2], CodeCommit.filter(:owned_by_support_identity => "rodney", :status => "verified").ids
    assert_equal [3], CodeCommit.filter(:owned_by_support_identity => "rodney", :status => "staged").ids
    assert_equal [6], CodeCommit.filter(:owned_by_support_identity => "rodney", :status => "deployed").ids
  end
  test "scopes" do
    assert_equal 6, CodeCommit.all.count
    assert_equal [1], CodeCommit.unmatched.ids
    assert_equal [2], CodeCommit.verified.ids
    assert_equal [3], CodeCommit.staged.ids
    assert_equal [4], CodeCommit.matched.ids
    assert_equal [5, 6], CodeCommit.deployed.ids
  end
  test "unmatch and reopen" do
    commit = CodeCommit.find(4)
    assert commit.matched?
    ticket = CodeTicket.find(5)
    assert ticket.committed?
    assert_equal [commit], ticket.code_commits
    assert_equal ticket, commit.code_ticket
    User.current_user = User.find_by_login("sam")
    assert commit.unmatch!
    assert commit.unmatched?
    assert_equal "committed -> unowned (unmatched from code commit)", ticket.code_details.system_log.last.content
    assert ticket.reload.unowned?
  end
  test "unmatch and unlink" do
    commit = CodeCommit.find(4)
    ticket = CodeTicket.find(5)
    assert_equal [commit], ticket.code_commits
    assert_equal ticket, commit.code_ticket

    new_commit = CodeCommit.find(1)
    User.current_user = User.find_by_login("sam")
    assert new_commit.match!(ticket.id)
    assert new_commit.matched?
    assert_equal ticket, new_commit.code_ticket
    assert_equal [new_commit, commit], ticket.reload.code_commits

    assert commit.unmatch!
    assert commit.unmatched?
    assert ticket.committed?
    assert_equal [new_commit], ticket.reload.code_commits
  end
  test "unmatch authorization" do
    commit = CodeCommit.find(4)
    assert_raise(SecurityError) { commit.unmatch! }
    User.current_user = User.find_by_login("jim")
    assert_raise(SecurityError) { commit.unmatch! }
  end
end
