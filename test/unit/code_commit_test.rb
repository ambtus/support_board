require 'test_helper'

class CodeCommitTest < ActiveSupport::TestCase
  test "normal flow" do
    assert CodeCommit.find(1).unmatched?
    assert CodeCommit.find(2).verified?
    assert CodeCommit.find(3).staged?
    assert CodeCommit.find(4).matched?
    assert CodeCommit.find(5).deployed?
  end
  test "find support id" do
    cc = CodeCommit.create(:author => "rodney")
    assert_equal cc.support_identity_id, SupportIdentity.find_by_name("rodney").id
  end
  test "no support id" do
    assert_nil SupportIdentity.find_by_name("new coder")
    assert cc = CodeCommit.create(:author => "new coder")
    assert SupportIdentity.find_by_name("new coder")
    assert_equal "new coder", cc.support_identity.name
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
