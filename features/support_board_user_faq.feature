Feature: FAQs as seen by logged in users

Scenario: users can view posted FAQs, but not comment
  Given I am logged in as "jim"
  When I am on the page for faq 1
  Then I should see "where to find salt"
    But I should not see "Details"

Scenario: users can comment on a draft FAQ
  Given I am logged in as "jim"
  When I am on the page for faq 2
  Then I should see "why we don't have enough ZPMs"
    And I fill in "Details" with "What's a ZPM?"
    And I press "Add details"
  Then I should see "jim wrote: What's a ZPM?"

Scenario: users reading a draft FAQ can mark it as "this answered my question" (a FAQ vote)
  Given I am logged in as "dean"
  When I am on the page for faq 2
  Then I should see "Votes: 0"
  When I press "This FAQ answered my question"
  Then I should see "Votes: 1"

Scenario: users reading a posted FAQ can mark it as "this answered my question" (a FAQ vote)
  Given I am logged in as "dean"
  When I am on the page for faq 1
  Then I should see "Votes: 0"
  When I press "This FAQ answered my question"
  Then I should see "Votes: 1"

Scenario: a posted faq should get a vote when linked from a user support ticket
  When I am on the page for faq 5
  Then I should see "what's a sentinel"
    And I should see "Votes: 1"

Scenario: users can remove a link to a draft FAQ if they don't think it resolves their ticket. also removes the vote.
  Given I am logged in as "jim"
  When I follow "jim"
    And I follow "jim's closed support tickets"
    And I follow "Support Ticket #6"
  Then I should see "closed by blair what's a sentinel?"
  When I fill in "Reason" with "I am not a freak!"
    And I press "Reopen"
  Then I should see "Status: open"
    And I should not see "what's a sentinel?" within "a"
  When I am on the page for faq 5
    Then I should see "what's a sentinel"
    And I should see "Votes: 0"

Scenario: users can remove a link to a posted FAQ if they don't think it resolves their ticket. also removes the vote.
  Given I am logged in as "john"
  When I am on the page for faq 4
  Then I should see "Votes: 1"
  When I follow "john"
    And I follow "john's closed support tickets"
    And I follow "Support Ticket #5"
  Then I should see "closed by rodney how to recover your password"
  When I fill in "Reason" with "Didn't work"
    And I press "Reopen"
  Then I should see "Status: open"
    And I should not see "how to recover your password" within "a"
  When I am on the page for faq 4
  Then I should see "Votes: 0"
