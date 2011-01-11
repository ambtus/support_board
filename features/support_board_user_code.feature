Feature: the support board as seen by logged in users for code tickets

Scenario: can view code tickets, vote on not-resolved tickets, and comment on not-worked tickets
  Given a volunteer exists with login: "oracle"
  And the following code tickets exist
    | summary                        | id |
    | something that could be better | 1  |
    | something that is  broken      | 2  |
    | something on the horizon       | 3  |
  And "oracle" resolves code ticket 1
  And "oracle" takes code ticket 2
  Given I am logged in as "curious"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
  Then I should not see "Code Ticket #1"
    But I should see "Code Ticket #2"
    And I should see "Code Ticket #3"
    And I should see "something that is broken"
    And I should see "something on the horizon"
  When I am on the first code ticket page
    Then I should see "Status: deployed in 1"
    And I should see "Votes: 0"
    And I should not see "Details"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #2"
    And I press "Vote for this ticket"
  Then I should see "Votes: 1"
    And I should see "something that is broken"
    And I should see "Status: taken by oracle"
    But I should not see "Details"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #3"
    And I should see "something on the horizon"
    And I should see "Votes: 0"
    And I should see "Status: open"
    And I should see "Details"

Scenario: users can (un)monitor open code tickets
  Given a code ticket exists with id: 1
  And a volunteer exists with login: "oracle"
  And I am logged in as "curious"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
    And I press "Watch this ticket"
  Then 0 email should be delivered to "curious@ao3.org"
  When "oracle" comments on code ticket 1
  Then 1 email should be delivered to "curious@ao3.org"
  When I click the first link in the email
  Then I should see "oracle (volunteer) wrote: foo bar"
  When I am logged in as "curious"
    And I am on the first code ticket page
  When I press "Don't watch this ticket"
    And all emails have been delivered
  When "oracle" comments on code ticket 1
  Then 0 emails should be delivered to "curious@ao3.org"

Scenario: users can (un)monitor worked code tickets
  Given a code ticket exists with id: 1
    And a volunteer exists with login: "oracle"
  When "oracle" takes code ticket 1
    And I am logged in as "curious"
    And I am on the first code ticket page
  When I press "Watch this ticket"
  Then 0 email should be delivered to "curious@ao3.org"
  When I am logged out
  When "oracle" comments on code ticket 1
  Then 1 email should be delivered to "curious@ao3.org"
    And I click the first link in the email
  Then I should see "Status: taken by oracle"
    And I am logged in as "curious"
    And I am on the first code ticket page
  When I press "Don't watch this ticket"
    And all emails have been delivered
  When "oracle" comments on code ticket 1
  Then 0 emails should be delivered to "curious@ao3.org"

Scenario: users can vote for open code tickets
  Given a code ticket exists with id: 1
  And I am logged in as "curious"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
    And I press "Vote for this ticket"
  Then I should see "Votes: 1"

Scenario: users can vote for worked code tickets
  Given a code ticket exists with id: 1
    And a volunteer exists with login: "oracle", id: 1
  And "oracle" takes code ticket 1
  And I am logged in as "curious"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
    And I press "Vote for this ticket"
  Then I should see "Votes: 1"

Scenario: users can't vote for closed code tickets
  Given a code ticket exists with id: 1
    And a volunteer exists with login: "oracle", id: 1
  And "oracle" resolves code ticket 1
  And I am logged in as "curious"
    And I am on the first code ticket page
    Then I should not see "Vote for this ticket"

Scenario: users can comment on open code tickets, but not closed code tickets
  Given a code ticket exists with id: 1
  And I am logged in as "curious"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
    And I fill in "Details" with "Have you tried ..."
    And I press "Add details"
  Then I should see "curious wrote: Have you tried"
  When a volunteer exists with login: "oracle"
    And "oracle" takes code ticket 1
  And I am logged in as "curious"
  When I am on the first code ticket page
  Then I should not see "Details"

Scenario: link to code tickets they've voted on, public
  Given a user exists with login: "helper", id: 1
  And the following code tickets exist
    | summary                        | id |
    | something that could be better | 1  |
    | something that is  broken      | 2  |
    | something on the horizon       | 3  |
  And "helper" votes for code ticket 1
  And "helper" votes for code ticket 3
  When I am on helper's user page
    And I follow "Code tickets voted up by helper"
  Then I should see "Code Ticket #1"
    And I should see "Code Ticket #3"
    But I should not see "Code Ticket #2"

Scenario: link to code tickets they've commented on, public
  Given a user exists with login: "helper", id: 1
  And the following code tickets exist
    | summary                        | id |
    | something that could be better | 1  |
    | something that is  broken      | 2  |
    | something on the horizon       | 3  |
  And "helper" comments on code ticket 1
  And "helper" comments on code ticket 3
  When I am on helper's user page
    And I follow "Code tickets commented on by helper"
  Then I should see "Code Ticket #1"
    And I should see "Code Ticket #3"
    But I should not see "Code Ticket #2"

Scenario: links to code tickets they're watching, private
  Given a user exists with login: "helper", id: 1
  And the following code tickets exist
    | summary                        | id |
    | something that could be better | 1  |
    | something that is  broken      | 2  |
    | something on the horizon       | 3  |
  And "helper" watches code ticket 1
  And "helper" watches code ticket 3
  When I am on helper's user page
    Then I should not see "watched"
  When I am logged in as "helper"
    And I follow "helper"
    And I follow "Code tickets I am watching"
  Then I should see "Code Ticket #1"
    And I should see "Code Ticket #3"
    But I should not see "Code Ticket #2"
