Feature: FAQs as seen by logged in users

Scenario: users can view posted FAQs, but not comment
  Given an archive faq exists with posted: true
  When I am on the first archive faq page
  Then I should see "faq 1"
    But I should not see "Add comment"

Scenario: users can comment on a draft FAQ
  Given an archive faq exists with posted: false
    And I am logged in as "someone"
  When I am on the first archive faq page
    And I fill in "Add comment" with "this sounds good"
    And I press "Update Archive faq"
  Then I should see "someone wrote: this sounds good"

Scenario: users can remove a link to a FAQ if they don't think it resolves their ticket
  Given I am logged in as "troubled"
  When I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer creates a faq from support ticket 1
    And I reload the page
  Then I should see "Status: Linked to FAQ by oracle"
    And I should see "1: faq 1"
  When I uncheck "linked to FAQ"
    And I press "Update Support ticket"
  Then I should see "Status: In progress"
    And I should not see "1: faq 1"

Scenario: users reading a FAQ can mark it as "this answered my question" (a FAQ vote)
  Given an archive faq exists with posted: true
    And I am logged in as "troubled"
  When I am on the first archive faq page
  Then I should see "faq 1"
  When I press "This FAQ answered my question"
  Then I should not see "Votes: 1"
  When I am logged in as volunteer "oracle"
    And I am on the first archive faq page
  Then I should see "Votes: 1"

Scenario: a posted archive faq should get a vote when linked from a user support ticket
  Given an archive faq exists with posted: true, position: 1
  When I am logged in as "troubled"
    And I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer links support ticket 1 to faq 1
  When I am logged in as "oracle"
    And I am on the first archive faq page
  Then I should see "Votes: 1"

Scenario: a posted archive faq should get a vote removed when unlinked from a user support ticket
  Given an archive faq exists with posted: true, position: 1
  When I am logged in as "troubled"
    And I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer links support ticket 1 to faq 1
    And I reload the page
  When I uncheck "linked to FAQ"
    And I press "Update Support ticket"
  When I am logged in as "oracle"
    And I am on the first archive faq page
  Then I should see "Votes: 0"

Scenario: an archive faq should get a vote from user support tickets when it's posted
  Given I am on the home page
  When I am logged in as "troubled"
    And I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
    And a volunteer creates a faq from support ticket 1
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I follow "Unposted FAQs"
    And I follow "1: faq 1"
    And I press "Post"
  Then I should see "Votes: 1"

Scenario: an archive faq should not get a vote when it's posted if there are no linked support tickets
  Given I am on the home page
  When I am logged in as "troubled"
    And I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer creates a faq from support ticket 1
    And I reload the page
  When I uncheck "linked to FAQ"
    And I press "Update Support ticket"
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I follow "Unposted FAQs"
    And I follow "1: faq 1"
    And I press "Post"
  Then I should see "Votes: 0"
