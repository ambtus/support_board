Feature: the support board as seen by logged in users for code tickets

Scenario: can view code tickets, vote on not-resolved tickets, and respond to not-worked tickets
  Given the following volunteers exist
    | login    | id |
    | oracle   | 1  |
  And the following code tickets exist
    | summary                        | id |
    | something that could be better | 1  |
    | something that is  broken      | 2  |
    | something on the horizon       | 3  |
  And "oracle" takes code ticket 1
  And "oracle" resolves code ticket 1
  And "oracle" takes code ticket 2
  Given I am logged in as "curious"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
  Then I should not see "Code Ticket #1"
    But I should see "Code Ticket #2"
    And I should see "something that is broken"
    And I should see "something on the horizon"
  When I am on the first code ticket page
    Then I should see "Status: Closed"
    And I should see "Votes: 0"
    And I should not see "Vote up"
    And I should not see "Add details"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #2"
  Then I should see "Vote up"
    And I should see "Votes: 0"
    And I should see "something that is broken"
    And I should see "Status: In progress"
    But I should not see "Add details"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #3"
    And I should see "something on the horizon"
    And I should see "Vote up"
    And I should see "Votes: 0"
    And I should see "Status: Open"
    And I should see "Add details"

Scenario: users can (un)monitor open code tickets
  Given a code ticket exists with id: 1
  And a volunteer exists with login: "oracle"
  And I am logged in as "curious"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
    And I check "Turn on notifications"
    And I press "Update Code ticket"
  Then 0 email should be delivered to "curious@ao3.org"
  When "oracle" comments on code ticket 1
  Then 1 email should be delivered to "curious@ao3.org"
  When I click the first link in the email
  Then I should see "Support volunteer oracle wrote: blah blah"
  When I am logged in as "curious"
    And I am on the first code ticket page
  When I check "Turn off notifications"
    And I press "Update Code ticket"
    And all emails have been delivered
  When "oracle" comments on code ticket 1
  Then 0 emails should be delivered to "curious@ao3.org"

Scenario: users can (un)monitor worked code tickets
  Given a code ticket exists with id: 1
    And a volunteer exists with login: "oracle"
  When "oracle" takes code ticket 1
    And I am logged in as "curious"
    And I am on the first code ticket page
  When I check "Turn on notifications"
    And I press "Update Code ticket"
  Then 0 email should be delivered to "curious@ao3.org"
  When I am logged out
  When "oracle" comments on code ticket 1
  Then 1 email should be delivered to "curious@ao3.org"
    And I click the first link in the email
  Then I should see "In progress"
    And I am logged in as "curious"
    And I am on the first code ticket page
  When I check "Turn off notifications"
    And I press "Update Code ticket"
    And all emails have been delivered
  When "oracle" comments on code ticket 1
  Then 0 emails should be delivered to "curious@ao3.org"

Scenario: users can (un)vote for open code tickets
  Given a code ticket exists with id: 1
  And I am logged in as "curious"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
    And I check "Vote up"
    And I press "Update Code ticket"
  Then I should see "Votes: 1"
  When I uncheck "Vote up"
    And I press "Update Code ticket"
  Then I should see "Votes: 0"

Scenario: users can (un)vote for worked code tickets
  Given a code ticket exists with id: 1
    And the following volunteers exist
    | login    | id |
    | oracle   | 1  |
  And "oracle" takes code ticket 1
  And I am logged in as "curious"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
    And I check "Vote up"
    And I press "Update Code ticket"
  Then I should see "Votes: 1"
  When I uncheck "Vote up"
    And I press "Update Code ticket"
  Then I should see "Votes: 0"

Scenario: users can't vote for closed code tickets
  Given a code ticket exists with id: 1
    And the following volunteers exist
    | login    | id |
    | oracle   | 1  |
  And "oracle" takes code ticket 1
  And "oracle" resolves code ticket 1
  And I am logged in as "curious"
    And I am on the first code ticket page
    Then I should not see "Vote up"

Scenario: users can't unvote for closed code tickets
  Given a code ticket exists with id: 1
    And the following volunteers exist
    | login    | id |
    | oracle   | 1  |
  And "oracle" takes code ticket 1
  And I am logged in as "curious"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
    And I check "Vote up"
    And I press "Update Code ticket"
  Then I should see "Votes: 1"
  When "oracle" resolves code ticket 1
    And I am on the first code ticket page
    Then I should not see "Vote up"

Scenario: users can comment on open code tickets, but not closed code tickets
  Given a code ticket exists with id: 1
  And I am logged in as "curious"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
    And I fill in "Add details" with "Have you tried ..."
    And I press "Update Code ticket"
  Then I should see "curious wrote: Have you tried"
  When the following volunteers exist
    | login    | id |
    | oracle   | 1  |
  When "oracle" takes code ticket 1
  And I am logged in as "curious"
  When I am on the first code ticket page
  Then I should not see "Add details"

Scenario: link to code tickets they've voted on, public
  Given the following activated users exist
    | login     | id |
    | helper    | 1  |
  And the following code tickets exist
    | summary                        | id |
    | something that could be better | 1  |
    | something that is  broken      | 2  |
    | something on the horizon       | 3  |
  And "helper" votes up code ticket 1
  And "helper" votes up code ticket 3
  When I am on helper's user page
    And I follow "Code tickets voted up by helper"
  Then I should see "Code Ticket #1"
    And I should see "Code Ticket #3"
    But I should not see "Code Ticket #2"

Scenario: link to code tickets they've commented on, public
  Given the following activated users exist
    | login     | id |
    | helper    | 1  |
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
  Given the following activated users exist
    | login     | id |
    | helper    | 1  |
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
