Feature: FAQs as seen by logged in users

Scenario: users can view posted FAQs, but not comment
  Given a posted faq exists
  When I am on the first faq page
  Then I should see "faq"
    But I should not see "Details"

Scenario: users can comment on a draft FAQ
  Given a faq exists
    And I am logged in as "someone"
  When I am on the first faq page
    And I fill in "Details" with "this sounds good"
    And I press "Add details"
  Then I should see "someone wrote: this sounds good"

Scenario: users can remove a link to a FAQ if they don't think it resolves their ticket
  Given I am logged in as "troubled"
  When I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer creates a faq from support ticket 1
    And I reload the page
  Then I should see "Status: closed by oracle"
    And I should see "1: new faq"
  When I fill in "Reason" with "not even close"
    And I press "Reopen"
  Then I should see "Status: open"
    And I should not see "1: new faq"

Scenario: users reading a FAQ can mark it as "this answered my question" (a FAQ vote)
  Given a posted faq exists with position: 1, title: "something"
    And I am logged in as "troubled"
  When I am on the first faq page
  Then I should see "something"
  When I press "This FAQ answered my question"
  Then I should see "Votes: 1"

Scenario: a posted faq should get a vote when linked from a user support ticket
  Given a posted faq exists with position: 1, title: "something"
  When I am logged in as "troubled"
    And I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer links support ticket 1 to faq 1
  When I am on the first faq page
  Then I should see "Votes: 1"

Scenario: a posted faq should get a vote removed when unlinked from a user support ticket
  Given a posted faq exists with position: 1, title: "something"
  When I am logged in as "troubled"
    And I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer links support ticket 1 to faq 1
    And I reload the page
  When I fill in "Reason" with "not even close"
    And I press "Reopen"
  When I am on the first faq page
  Then I should see "Votes: 0"

Scenario: a faq should get a vote from user support tickets when it's posted
  Given I am on the home page
  When I am logged in as "troubled"
    And I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
    And a volunteer creates a faq from support ticket 1
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I follow "Unposted FAQs"
    And I follow "1: new faq"
    And I press "Post"
  Then I should see "Votes: 1"

Scenario: a faq should not get a vote when it's posted if there are no linked support tickets
  Given I am on the home page
  When I am logged in as "troubled"
    And I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer creates a faq from support ticket 1
    And I reload the page
  When I fill in "Reason" with "not even close"
    And I press "Reopen"
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I follow "Unposted FAQs"
    And I follow "1: new faq"
    And I press "Post"
  Then I should see "Votes: 0"
