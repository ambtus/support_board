Feature: the various ways volunteers can resolve support tickets

Scenario: volunteers can mark a support ticket spam/ham
  Given a support ticket exists with summary: "buy viagra", id: 1
    And all emails have been delivered
  When I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Mark as spam"
  Then 0 emails should be delivered to "guest@ao3.org"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Spam"
  Then I should see "Support Ticket #1"
    When I go to the first support ticket page
    And I press "Mark as ham"
  Then 0 emails should be delivered to "guest@ao3.org"
  When I follow "Support Board"
    And I follow "Spam"
  Then I should not see "Support Ticket #1"

Scenario: volunteers can not mark a user opened support ticket spam
  Given a user exists with login: "troubled", id: 1
    And a support ticket exists with summary: "buy viagra", id: 1, user_id: 1
  When I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
  # FIXME this doesn't fail when the code is wrong: can't "see" submit labels
  Then I should not see "Spam"

Scenario: volunteers can mark a support ticket for an Admin to resolve
  Given the following support tickets exist
    | summary       | id |
    | needs admin   | 1  |
    | question      | 2  |
  When I am logged in as volunteer "oracle"
    And I go to the first support ticket page
    And I press "Needs admin attention"
  When I follow "Support Board"
    And I follow "Support tickets requiring Admin attention"
  Then I should see "Support Ticket #1"
    But I should not see "Support Ticket #2"

Scenario: volunteers can mark a support ticket as a Comment (don't require any work)
  Given a support ticket exists with id: 1
  When I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Post as comment"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Comments"
    And I follow "#1"
  Then I should see "Status: posted by oracle"
  When I fill in "Reason" with "oops"
    And I press "Reopen"
    And I press "Needs admin attention"
  Then I should see "Status: waiting for an admin"
  When I follow "Support Board"
    And I follow "Comments"
  Then I should not see "#1"
  When I follow "Support Board"
    And I follow "Support tickets requiring Admin attention"
  Then I should see "Support Ticket #1"

Scenario: volunteers can link a support ticket to an existing code ticket
  Given a support ticket exists with id: 1
    And a code ticket exists with id: 1
  When I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I select "1" from "Code Ticket"
    And I press "Needs this fix"
  Then 1 emails should be delivered to "guest@ao3.org"
  When I am on the page for the first code ticket
  Then I should see "Votes: 2"
    And I should see "Related Support tickets"
  When I follow "1"
  Then I should see "Status: waiting for a code fix Code Ticket #1"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Support Tickets waiting for Code changes"
    And I follow "Support Ticket #1"
  When I fill in "Reason" with "wrong code ticket"
    And I press "Reopen"
  When I am on the first code ticket page
  Then I should see "Votes: 0"
    And I should not see "Support Ticket #1"
  When I am on the first support ticket page
    Then I should see "Status: open"

Scenario: volunteers can open a new code ticket and link to it in one step (with the summary pre-filled in but editable)
  Given a support ticket exists with id: 1, summary: "something is broken"
  When I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Create new code ticket"
  Then 1 emails should be delivered to "guest@ao3.org"
  When I fill in "Summary" with "something major is broken"
    And I fill in "Description" with "blah blah and some more blah"
    And I press "Update Code ticket"
  Then I should see "Summary: something major is broken"
    And I should see "Description: blah blah and some more blah"
    And I should see "Votes: 3"
  When I follow "1"
  Then I should see "Status: waiting for a code fix Code Ticket #"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Support Tickets waiting for Code changes"
  Then I should see "Support Ticket #1"

Scenario: volunteers can link a support ticket to an existing draft FAQ
  Given a faq exists with position: 1, title: "some question"
    And a support ticket exists with id: 1
  When I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I select "some question" from "FAQ"
    And I press "Answered by this FAQ"
  Then 1 emails should be delivered to "guest@ao3.org"
    And I should see "Status: closed by oracle some question"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Closed Support Tickets"
    And I follow "Support Ticket #1"
  When I fill in "Reason" with "incorrect FAQ"
    And I press "Reopen"
    Then I should see "Status: open"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
    Then I should not see "some question"

Scenario: volunteers can link a support ticket to an existing posted FAQ
  Given a posted faq exists with position: 1, title: "some question"
    And a support ticket exists with id: 1
  When I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I select "some question" from "FAQ"
    And I press "Answered by this FAQ"
  Then I should see "Status: closed by oracle some question"
    And 1 email should be delivered to "guest@ao3.org"
  When I follow "some question"
  Then I should see "Votes: 1"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Closed Support Tickets"
    And I follow "Support Ticket #1"
  When I fill in "Reason" with "incorrect FAQ"
    And I press "Reopen"
  Then I should see "Status: open"
    And I should not see "some question" within "a"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
    And I follow "some question"
  Then I should see "Votes: 0"

Scenario: volunteers can create a new (draft) FAQ and link to it in one step
  Given a support ticket exists with id: 1, summary: "some question"
  When I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Create new FAQ"
  Then 1 emails should be delivered to "guest@ao3.org"
    And I should not see "some question"
  When I fill in "Title" with "New question"
    And I press "Update Faq"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
    Then I should not see "New question"
  When I follow "Support Board"
    And I follow "FAQs waiting for comments"
    Then I should see "New question"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Closed Support Tickets"
    And I follow "Support Ticket #1"
  Then I should see "Status: closed by oracle New question"
  When I fill in "Reason" with "incorrect FAQ"
    And I press "Reopen"
  Then I should see "Status: open"

Scenario: volunteers can send email to another volunteer asking them to take a ticket
  Given a support ticket exists
    And a volunteer exists with login: "oracle", id: 1
    And a volunteer exists with login: "hermione", id: 2
    And all emails have been delivered
  When I am logged in as "oracle"
    And I am on the first support ticket page
    Then I should see "Status: open"
  When I select "hermione" from "Support Volunteers"
    And I press "Send request to take"
  Then 1 email should be delivered to "hermione@ao3.org"
    And the email should contain "Please consider taking"
    And the email should contain "Support Ticket #1"
    And the email should contain "Thank you, oracle"
  When I click the first link in the email
  Then I should see "Status: open"

Scenario: volunteers can verify staged Tickets
