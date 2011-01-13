Feature: the support board as seen by logged in users for code tickets

Scenario: users can view open code tickets, and vote and comment
  When I am logged in as "dean"
    And I am on the page for the first code ticket
  Then I should see "Status: open"
  When I press "Vote up"
    Then I should see "Votes: 1"
  When I fill in "Details" with "would be great if"
    And I press "Add details"
  Then I should see "dean wrote: would be great if"

Scenario: users can view in progress code tickets, and vote but not comment
  When I am logged in as "dean"
    And I am on the page for the second code ticket
  Then I should see "Status: taken"
    But I should not see "Details:"
  When I press "Vote up"
    Then I should see "Votes: 1"

Scenario: guests can view closed code tickets, but not vote or comment
  When I am logged in as "dean"
    And I am on the page for the last code ticket
  Then I should see "Status: deployed in 1.0"
    But I should not see "Details:"
    And I should not see "Vote up"

Scenario: can see all open tickets
  Given I am logged in as "jim"
  When I follow "Support Board"
    And I follow "Open Code Tickets (Known Issues)"
  Then I should not see "Code Ticket #6"
    But I should see "Code Ticket #1 (0) fix the roof"
    And I should see "Code Ticket #2 (0) save the world"
    And I should see "Code Ticket #3 (2) repeal DADA"
    And I should see "Code Ticket #4 (0) build a zpm"
    And I should see "Code Ticket #5 (2) find a sentinel"

Scenario: users can (un)monitor open code tickets
  Given I am logged in as "jim"
    And I am on the page for the first code ticket
    And I press "Watch this ticket"
  Then 0 email should be delivered to "jim@ao3.org"
  When "sam" comments on code ticket 1
  Then 1 email should be delivered to "jim@ao3.org"
    And all emails have been delivered
  When I click the first link in the email
  Then I should see "sam (volunteer) wrote: foo bar"
  # clicking links in email in capybara looses your session
  Given I am logged in as "jim"
    And I am on the page for the first code ticket
  When I press "Don't watch this ticket"
    And "sam" comments on code ticket 1
  Then 0 emails should be delivered to "jim@ao3.org"

Scenario: users can (un)monitor worked code tickets
  Given I am logged in as "jim"
    And I am on the page for the second code ticket
    And I press "Watch this ticket"
  Then 0 email should be delivered to "jim@ao3.org"
  When "blair" comments on code ticket 2
  Then 1 email should be delivered to "jim@ao3.org"
    And all emails have been delivered
  When I click the first link in the email
  Then I should see "blair (volunteer) wrote: foo bar"
  # clicking links in email in capybara looses your session
  Given I am logged in as "jim"
    And I am on the page for the second code ticket
  When I press "Don't watch this ticket"
    And "blair" comments on code ticket 2
  Then 0 emails should be delivered to "jim@ao3.org"

Scenario: link to code tickets they've voted on, public
  Given "jim" votes for code ticket 2
  And "jim" votes for code ticket 5
  When I am on jim's user page
    And I follow "Code tickets voted up by jim"
  Then I should see "Code Ticket #2"
    And I should see "Code Ticket #5"
    But I should not see "Code Ticket #1"
    And I should not see "Code Ticket #3"

Scenario: link to code tickets they've commented on, public
  Given "jim" comments on code ticket 1
  When I am on jim's user page
    And I follow "Code tickets commented on by jim"
  Then I should see "Code Ticket #1"
    And I should see "Code Ticket #5"
    But I should not see "Code Ticket #2"

Scenario: links to code tickets they're watching, private
  Given "jim" watches code ticket 1
    And "jim" watches code ticket 2
    And "jim" watches code ticket 5
  When I am on jim's user page
    Then I should not see "watched"
  When I am logged in as "jim"
    And I follow "jim"
    And I follow "Code tickets I am watching"
  Then I should see "Code Ticket #1"
    And I should see "Code Ticket #2"
    And I should see "Code Ticket #5"
    But I should not see "Code Ticket #3"
