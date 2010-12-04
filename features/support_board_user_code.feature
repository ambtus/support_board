Feature: the support board as seen by logged in users for code tickets

Scenario: can view code tickets, vote on not-resolved tickets, and respond to not-worked tickets
  Given the following activated support volunteer exists
    | login    | id |
    | oracle   | 1  |
  And the following code tickets exist
    | summary                        | category | id |
    | something that could be better | Irritant | 1  |
    | something that is  broken      | Bug      | 2  |
    | something on the horizon       | Feature  | 3  |
  And "oracle" takes code ticket 1
  And "oracle" resolves code ticket 1
  And "oracle" takes code ticket 2
  Given I am logged in as "curious"
  When I follow "Support"
    And I follow "Open Code Tickets"
  Then I should not see "Code Ticket #1"
    But I should see "Code Ticket #2"
    And I should see "something that is broken"
    And I should see "something on the horizon"
  When I am on the first code ticket page
    Then I should see "Status: Closed by oracle"
    And I should see "Votes: 0"
    And I should not see "Vote up"
    And I should not see "Add details"
  When I follow "Support"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #2"
  Then I should see "Vote up"
    And I should see "Votes: 0"
    And I should see "Category: Bug"
    And I should see "something that is broken"
    And I should see "Status: Being worked by oracle"
    But I should not see "Add details"
  When I follow "Support"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #3"
    Then I should see "Category: Feature"
    And I should see "something on the horizon"
    And I should see "Vote up"
    And I should see "Votes: 0"
    And I should see "Status: Open"
    And I should see "Add details"

Scenario: users can (un)monitor open code tickets
  Given the following code tickets exist
    | summary                        | category | id |
    | something that could be better | Irritant | 1  |
  And I am logged in as "curious"
  When I follow "Support"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
    And I check "Turn on notifications"
    And I press "Update Code ticket"
  Then 0 email should be delivered to "curious@ao3.org"
  When a support volunteer responds to code ticket 1
  Then 1 email should be delivered to "curious@ao3.org"
  When I click the first link in the email
  Then I should see "something that could be better"
  When I am logged in as "curious"
    And I am on the first code ticket page
  When I check "Turn off notifications"
    And I press "Update Code ticket"
    And all emails have been delivered
  When a support volunteer responds to code ticket 1
  Then 0 emails should be delivered to "curious@ao3.org"

Scenario: users can (un)monitor worked code tickets
  Given the following activated support volunteer exists
    | login    | id |
    | oracle   | 1  |
  And the following code tickets exist
    | summary                        | category | id |
    | something that could be better | Irritant | 1  |
  And "oracle" takes code ticket 1
  And I am logged in as "curious"
    And I am on the first code ticket page
  When I check "Turn on notifications"
    And I press "Update Code ticket"
  Then 0 email should be delivered to "curious@ao3.org"
  When a support volunteer responds to code ticket 1
  Then 1 email should be delivered to "curious@ao3.org"
  When I click the first link in the email
  Then I should see "something that could be better"
  When I am logged in as "curious"
    And I am on the first code ticket page
  When I check "Turn off notifications"
    And I press "Update Code ticket"
    And all emails have been delivered
  When a support volunteer responds to code ticket 1
  Then 0 emails should be delivered to "curious@ao3.org"


Scenario: users can (un)vote for open code tickets
  Given the following code tickets exist
    | summary                        | category | id |
    | something that could be better | Irritant | 1  |
  And I am logged in as "curious"
  When I follow "Support"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
    And I check "Vote up"
    And I press "Update Code ticket"
  Then I should see "Votes: 1"
  When I uncheck "Vote up"
    And I press "Update Code ticket"
  Then I should see "Votes: 0"

Scenario: users can (un)vote for worked code tickets
  Given the following activated support volunteer exists
    | login    | id |
    | oracle   | 1  |
  And the following code tickets exist
    | summary                        | category | id |
    | something that could be better | Irritant | 1  |
  And "oracle" takes code ticket 1
  And I am logged in as "curious"
  When I follow "Support"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
    And I check "Vote up"
    And I press "Update Code ticket"
  Then I should see "Votes: 1"
  When I uncheck "Vote up"
    And I press "Update Code ticket"
  Then I should see "Votes: 0"

Scenario: users can't vote for closed code tickets
  Given the following activated support volunteer exists
    | login    | id |
    | oracle   | 1  |
  And the following code tickets exist
    | summary                        | category | id |
    | something that could be better | Irritant | 1  |
  And "oracle" takes code ticket 1
  And "oracle" resolves code ticket 1
  And I am logged in as "curious"
    And I am on the first code ticket page
    Then I should not see "Vote up"

Scenario: users can't unvote for closed code tickets
  Given the following activated support volunteer exists
    | login    | id |
    | oracle   | 1  |
  And the following code tickets exist
    | summary                        | category | id |
    | something that could be better | Irritant | 1  |
  And "oracle" takes code ticket 1
  And I am logged in as "curious"
  When I follow "Support"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
    And I check "Vote up"
    And I press "Update Code ticket"
  Then I should see "Votes: 1"
  When "oracle" resolves code ticket 1
    And I am on the first code ticket page
    Then I should not see "Vote up"
