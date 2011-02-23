require 'test_helper'

class CodeCommitTest < ActiveSupport::TestCase
  test "validate author" do
    assert_raise(ActiveRecord::RecordInvalid) { CodeCommit.create! }
    assert CodeCommit.create!(:author => "someone")
  end
  test "name" do
    assert_equal "Code Commit #1", CodeCommit.find(1).name
  end
  test "summary" do
    assert_equal "this should fix it", CodeCommit.find(1).summary
  end
  test "empty summary" do
    commit = CodeCommit.create(:author => "sam")
    assert_equal "",commit.summary
  end
  test "long summary with newlines" do
    commit = CodeCommit.create(:author => "sam", :message => "short\nsecond line\n#{SecureRandom.hex(100)}")
    assert_equal "short", commit.summary
  end
  test "long summary without spaces" do
    message = SecureRandom.hex(141)
    commit = CodeCommit.create(:author => "sam", :message => message)
    assert_equal message, commit.summary
  end
  test "long summary without spaces with newlines" do
    message = SecureRandom.hex(141)
    commit = CodeCommit.create(:author => "sam", :message => "#{message}\nsecond line")
    assert_equal message, commit.summary
  end
  test "long summary with spaces" do
    first = SecureRandom.hex(100)
    commit = CodeCommit.create(:author => "sam", :message => "#{first} #{SecureRandom.hex(50)}")
    assert_equal first + "...", commit.summary
  end
  test "long summary with spaces and newlines" do
    first = SecureRandom.hex(100)
    commit = CodeCommit.create(:author => "sam", :message => "#{first} #{SecureRandom.hex(50)}\nmore stuff")
    assert_equal first + "...", commit.summary
  end
  test "info" do
    assert_match "] sam (unmatched)", CodeCommit.find(1).info
    assert_match "] rodney (verified)", CodeCommit.find(2).info
    assert_match "] rodney (staged)", CodeCommit.find(3).info
    assert_match "] blair (matched)", CodeCommit.find(4).info
    assert_match "] sidra (deployed)", CodeCommit.find(5).info
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
    User.current_user = User.find_by_login("sidra")
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
    assert_equal [6, 3, 2], CodeCommit.filter(:owned_by_support_identity => "rodney", :status => "all").ids
    assert_equal [5], CodeCommit.filter(:owned_by_support_identity => "sidra", :status => "all").ids
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
    assert_equal [5, 6], CodeCommit.filter(:status => "deployed", :sort_by => "oldest first").ids
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
  test "single create_commits_from_json" do
    json = <<EOF
{
  "after": "b4e2b8f073cdd563e27d990bbf68063250dca7e7",
  "before": "09ba484417c4656b2fbc33bd4889174e99dc9b53",
  "commits": [
    {
      "added": [],
      "author": {
        "email": "alice@alum.mit.edu",
        "name": "Sidra",
        "username": "ambtus"
      },
      "id": "b4e2b8f073cdd563e27d990bbf68063250dca7e7",
      "message": "feature stuff",
      "modified": [
        "features\/support_board_volunteer_code.feature",
        "features\/support_board_volunteer_resolution.feature"
      ],
      "removed": [],
      "timestamp": "2010-12-17T09:38:02-08:00",
      "url": "https:\/\/github.com\/ambtus\/support_board\/commit\/b4e2b8f073cdd563e27d990bbf68063250dca7e7"
    }
  ],
  "compare": "https:\/\/github.com\/ambtus\/support_board\/compare\/09ba484...b4e2b8f",
  "forced": false,
  "pusher": {
    "email": "github@ambt.us",
    "name": "ambtus"
  },
  "ref": "refs\/heads\/app",
  "repository": {
    "created_at": "2010\/12\/02 10:34:09 -0800",
    "description": "integrated support board",
    "fork": true,
    "forks": 0,
    "has_downloads": true,
    "has_issues": true,
    "has_wiki": true,
    "homepage": "",
    "name": "support_board",
    "open_issues": 0,
    "owner": {
      "email": "github@ambt.us",
      "name": "ambtus"
    },
    "private": false,
    "pushed_at": "2010\/12\/17 09:38:33 -0800",
    "url": "https:\/\/github.com\/ambtus\/support_board",
    "watchers": 1
  }
}
EOF
    assert_equal 6, CodeCommit.count
    payload = JSON.parse(json)
    CodeCommit.create_commits_from_json(payload)
    assert_equal 7, CodeCommit.count
    new_cc = CodeCommit.last
    assert_equal "Sidra", new_cc.author
    assert_equal "https://github.com/ambtus/support_board/commit/b4e2b8f073cdd563e27d990bbf68063250dca7e7", new_cc.url
    assert_equal "2010/12/17 09:38:33 -0800".to_time, new_cc.pushed_at
    assert_equal "feature stuff", new_cc.message
  end
  test "multiple create_commits_from_json" do
    json = <<EOF
{
  "after": "a3750699a35db5e6c74f7808fceb952f8e75d2cb",
  "before": "088d233dd0d52214b7f167dad6e8fd06c34a6c75",
  "commits": [
    {
      "added": [],
      "author": {
        "email": "alice@alum.mit.edu",
        "name": "Sidra",
        "username": "ambtus"
      },
      "id": "e89ce12f4ce7d051994b91e739de6f07220b92be",
      "message": "more work to make code independent of otwarchive code.",
      "modified": [
        "app\/models\/code_ticket.rb",
        "features\/support_board_volunteer_code.feature"
      ],
      "removed": [
        "app\/controllers\/known_issues_controller.rb"
      ],
      "timestamp": "2010-12-21T16:15:46-08:00",
      "url": "https:\/\/github.com\/ambtus\/support_board\/commit\/e89ce12f4ce7d051994b91e739de6f07220b92be"
    },
    {
      "added": [],
      "author": {
        "email": "alice@alum.mit.edu",
        "name": "Sidra",
        "username": "ambtus"
      },
      "id": "eb9bfb44521b53d7b5f4b39af71d6462ae172ae5",
      "message": "removed unused admin model (all admin functions will be taken by support admins)",
      "modified": [
        "app\/controllers\/application_controller.rb",
        "features\/support_board_volunteer_code.feature"
      ],
      "removed": [
        "app\/controllers\/admin_posts_controller.rb",
        "features\/step_definitions\/admin_steps.rb"
      ],
      "timestamp": "2010-12-21T16:53:42-08:00",
      "url": "https:\/\/github.com\/ambtus\/support_board\/commit\/eb9bfb44521b53d7b5f4b39af71d6462ae172ae5"
    },
    {
      "added": [
        "app\/models\/support_identity.rb",
        "features\/support_identity.feature"
      ],
      "author": {
        "email": "alice@alum.mit.edu",
        "name": "Sidra",
        "username": "ambtus"
      },
      "id": "a3750699a35db5e6c74f7808fceb952f8e75d2cb",
      "message": "removed dependency on otwarchive pseud model. added a new support identity model",
      "modified": [
        "app\/controllers\/code_tickets_controller.rb",
        "features\/support_board_volunteer_resolution.feature"
      ],
      "removed": [
        "app\/controllers\/pseuds_controller.rb",
        "features\/pseud.feature"
      ],
      "timestamp": "2010-12-23T11:10:04-08:00",
      "url": "https:\/\/github.com\/ambtus\/support_board\/commit\/a3750699a35db5e6c74f7808fceb952f8e75d2cb"
    }
  ],
  "compare": "https:\/\/github.com\/ambtus\/support_board\/compare\/088d233...a375069",
  "forced": false,
  "pusher": {
    "email": "github@ambt.us",
    "name": "ambtus"
  },
  "ref": "refs\/heads\/app",
  "repository": {
    "created_at": "2010\/12\/02 10:34:09 -0800",
    "description": "integrated support board",
    "fork": true,
    "forks": 0,
    "has_downloads": true,
    "has_issues": false,
    "has_wiki": false,
    "homepage": "",
    "name": "support_board",
    "open_issues": 0,
    "owner": {
      "email": "github@ambt.us",
      "name": "ambtus"
    },
    "private": false,
    "pushed_at": "2010\/12\/23 11:10:40 -0800",
    "url": "https:\/\/github.com\/ambtus\/support_board",
    "watchers": 1
  }
}
EOF
    assert_equal 6, CodeCommit.count
    payload = JSON.parse(json)
    CodeCommit.create_commits_from_json(payload)
    assert_equal 9, CodeCommit.count
    new_cc = CodeCommit.all[6]
    assert_equal "Sidra", new_cc.author
    assert_equal "https://github.com/ambtus/support_board/commit/e89ce12f4ce7d051994b91e739de6f07220b92be", new_cc.url
    assert_equal "2010/12/23 11:10:40 -0800".to_time, new_cc.pushed_at
    assert_equal "more work to make code independent of otwarchive code.", new_cc.message
    new_cc = CodeCommit.last
    assert_equal "Sidra", new_cc.author
    assert_equal "https://github.com/ambtus/support_board/commit/a3750699a35db5e6c74f7808fceb952f8e75d2cb", new_cc.url
    assert_equal "2010/12/23 11:10:40 -0800".to_time, new_cc.pushed_at
    assert_equal "removed dependency on otwarchive pseud model. added a new support identity model", new_cc.message
  end
end
