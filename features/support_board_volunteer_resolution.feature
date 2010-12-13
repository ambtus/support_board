Feature: the various ways volunteers can resolve support tickets

Scenario: volunteers can mark a support ticket spam/ham
  Given the following support tickets exist
    | summary       | id |
    | buy viagra    | 1  |
    And all emails have been delivered
  When I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Spam"
  Then 0 emails should be delivered to "guest@ao3.org"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Spam"
  Then I should see "Support Ticket #1"
    When I go to the first support ticket page
    And I press "Ham"
  Then 0 emails should be delivered to "guest@ao3.org"
  When I follow "Support Board"
    And I follow "Spam"
  Then I should not see "Support Ticket #1"

Scenario: volunteers can not mark a user opened support ticket spam
  Given a user exists with login: "troubled", id: 1
  And the following support tickets exist
    | id | summary       | user_id |
    | 1  | buy viagra    | 1       |
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
    And I press "Needs Admin Attention"
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
    And I press "Comment"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Comments"
    And I follow "#1"
  Then I should see "Status: Linked to Comments"
    When I press "Needs Attention"
  Then I should see "Status: Open"
  When I follow "Support Board"
    And I follow "Comments"
  Then I should not see "#1"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should see "Support Ticket #1"

Scenario: volunteers can link a support ticket to an existing code ticket
  Given a support ticket exists with id: 1
    And a code ticket exists with id: 1
  When I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I select "Code Ticket #1" from "Code Ticket"
    And I press "Link to Code ticket"
  Then 1 emails should be delivered to "guest@ao3.org"
    And I should see "Votes: 2"
    And I should see "Related Support tickets"
  When I follow "Support Ticket #1"
  Then I should see "Status: Linked to Code Ticket #1"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Support Tickets waiting for Code changes"
    And I follow "Support Ticket #1"
    And I press "Remove link to Code ticket"
  When I am on the first code ticket page
  Then I should see "Votes: 0"
    And I should not see "Support Ticket #1"
  When I am on the first support ticket page
    Then I should see "Status: In progress"

Scenario: volunteers can open a new code ticket and link to it in one step (with the summary pre-filled in but editable)
  Given a support ticket exists with id: 1, summary: "something is broken"
  When I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Create new Code ticket"
  Then 1 emails should be delivered to "guest@ao3.org"
    And I should see "Votes: 2"
  When I fill in "Summary" with "something major is broken"
    And I fill in "Add details" with "there's more information in Support Ticket #1"
    And I press "Update Code ticket"
  Then I should see "Summary: something major is broken"
    And I should see "volunteer oracle wrote: there's more information"
  When I follow "Support Ticket #1"
  Then I should see "Status: Linked to Code Ticket #"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Support Tickets waiting for Code changes"
  Then I should see "Support Ticket #1"

Scenario: volunteers can link a support ticket to an existing draft FAQ
  Given an archive faq exists with position: 1, title: "some question", posted: false
    And a support ticket exists with id: 1
  When I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I select "1: some question" from "FAQ"
    And I press "Link to FAQ"
  Then 1 emails should be delivered to "guest@ao3.org"
    And I should see "Status: Linked to FAQ by oracle"
    And I should see "1: some question"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Support Tickets linked to FAQs"
    And I follow "Support Ticket #1"
    And I press "Remove link to FAQ"
    Then I should see "Status: In progress"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
    Then I should not see "1: some question"

Scenario: volunteers can link a support ticket to an existing posted FAQ
  Given an archive faq exists with position: 1, title: "some question", posted: true
    And a support ticket exists with id: 1
  When I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I select "1: some question" from "FAQ"
    And I press "Link to FAQ"
  Then I should see "Status: Linked to FAQ by oracle"
    And 1 email should be delivered to "guest@ao3.org"
  When I follow "1: some question"
  Then I should see "Votes: 1"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Support Tickets linked to FAQs"
    And I follow "Support Ticket #1"
    And I press "Remove link to FAQ"
    Then I should see "Status: In progress"
    And I should not see "1: some question" within "a"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
    And I follow "1: some question"
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
    And I press "Update Archive faq"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Support Tickets linked to FAQs"
    And I follow "Support Ticket #1"
  Then I should see "Status: Linked to FAQ by oracle"
    And I should see "1: New question"
  When I press "Remove link to FAQ"
    Then I should see "Status: In progress"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
    Then I should not see "1: New question"

Scenario: FAQs can be sorted by votes

Scenario: code tickets can be sorted by votes

Scenario: volunteers can send email to another volunteer asking them to take a ticket

