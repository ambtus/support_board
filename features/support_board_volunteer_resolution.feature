Feature: the various ways support volunteers can resolve support tickets

Scenario: support volunteers can mark a support ticket spam/ham
  Given the following support tickets exist
    | summary       | id |
    | buy viagra    | 1  |
    And all emails have been delivered
  When I am logged in as support volunteer "oracle"
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

Scenario: support volunteers can not mark a user opened support ticket spam
  Given the following activated user exists
    | login     | id |
    | troubled  | 1  |
  And the following support tickets exist
    | id | summary       | user_id |
    | 1  | buy viagra    | 1       |
  When I am logged in as support volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
  # FIXME this doesn't fail when the code is wrong: can't "see" submit labels
  Then I should not see "Spam"

Scenario: support volunteers can mark a support ticket for an Admin to resolve
  Given the following support tickets exist
    | summary       | id |
    | needs admin   | 1  |
    | question      | 2  |
  When I am logged in as support volunteer "oracle"
    And I go to the first support ticket page
    And I press "Needs Admin Attention"
  When I follow "Support Board"
    And I follow "Support tickets requiring Admin attention"
  Then I should see "Support Ticket #1"
    But I should not see "Support Ticket #2"

Scenario: support volunteers can mark a support ticket as a Comment (don't require any work)
  Given a support ticket exists with id: 1
  When I am logged in as support volunteer "oracle"
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

Scenario: support volunteers can link a support ticket to an existing code ticket
  Given a support ticket exists with id: 1
    And a code ticket exists with id: 1
  When I am logged in as support volunteer "oracle"
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

Scenario: support volunteers can open a new code ticket and link to it in one step (with the summary pre-filled in but editable)
  Given a support ticket exists with id: 1, summary: "something is broken"
  When I am logged in as support volunteer "oracle"
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
    And I should see "Support volunteer oracle(SV) wrote: there's more information"
  When I follow "Support Ticket #1"
  Then I should see "Status: Linked to Code Ticket #"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Support Tickets waiting for Code changes"
  Then I should see "Support Ticket #1"

Scenario: support volunteers can link a support ticket to an existing FAQ
  Given an archive faq exists with id: 1, title: "some information"
    And a support ticket exists with id: 1
  When I am logged in as support volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I select "#1: some information" from "FAQ"
    And I press "Link to FAQ"
  Then 1 emails should be delivered to "guest@ao3.org"
    And I should see "Status: Linked to FAQ #1: some information by oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Support Tickets linked to FAQs"
    And I follow "Support Ticket #1"
    And I press "Remove link to FAQ"
    Then I should see "Status: In progress"

Scenario: support volunteers can create a new (draft) FAQ and link to it in one step (with some of the information pre-filled)

Scenario: when a draft FAQ is posted, the attached support tickets will get marked resolved. (??)
