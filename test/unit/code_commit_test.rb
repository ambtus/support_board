require 'test_helper'

class CodeCommitTest < ActiveSupport::TestCase
  test "find support id" do
    cc = CodeCommit.create(:author => "rodney")
    assert_equal cc.support_identity_id, SupportIdentity.find_by_name("rodney").id
  end
  test "no support id" do
    assert cc = CodeCommit.create(:author => "new coder")
    assert_nil cc.support_identity_id
  end
  test "no match" do
    cc = CodeCommit.create(:author => "sam")
    assert cc.unmatched?
  end
  test "auto match" do
    assert ct2 = CodeTicket.find(2)
    assert ct2.taken?
    cc = CodeCommit.create(:author => "sam", :message => "closes issue 2")
    assert cc.reload.matched?
    assert_equal ct2, cc.code_ticket
    assert_equal cc, ct2.code_commits.first
    assert ct2.reload.committed?
  end
  test "match" do
    assert ct1 = CodeTicket.find(1)
    assert ct1.unowned?
    cc = CodeCommit.create(:author => "sam")
    assert cc.unmatched?
    assert ct1.commit!(cc.id)
    assert cc.reload.matched?
    assert_equal ct1, cc.code_ticket
    assert_equal cc, ct1.code_commits.first
    assert ct1.committed?
  end
end
