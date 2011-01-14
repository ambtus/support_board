Feature: code tickets are for when something in the code needs to be fixed

Scenario: guests can view open code tickets, but not vote or comment
  When I am on the page for code ticket 1
  Then I should see "Status: open"
  But I should not see "Vote up"
    And I should not see "Details:"

Scenario: users can view open code tickets, and vote and comment
  When I am logged in as "dean"
    And I am on the page for code ticket 1
  Then I should see "Status: open"
  When I press "Vote up"
    Then I should see "Votes: 1"
  When I fill in "Details" with "would be great if"
    And I press "Add details"
  Then I should see "dean wrote: would be great if"

Scenario: guests can view in progress code tickets, but not vote or comment
  When I am on the page for code ticket 2
  Then I should see "Status: taken"
  But I should not see "Vote up"
    And I should not see "Details:"

Scenario: users can view in progress code tickets, and vote but not comment
  When I am logged in as "dean"
    And I am on the page for code ticket 2
  Then I should see "Status: taken"
    But I should not see "Details:"
  When I press "Vote up"
    Then I should see "Votes: 1"

Scenario: guests can view closed code tickets, but not vote or comment
  When I am on the page for the last code ticket
  Then I should see "Status: deployed in 1.0"
  But I should not see "Vote up"
    And I should not see "Details:"

Scenario: guests can view closed code tickets, but not vote or comment
  When I am logged in as "dean"
    And I am on the page for code ticket 6
  Then I should see "Status: deployed in 1.0"
    But I should not see "Details:"
    And I should not see "Vote up"

Scenario: can see all open code tickets
  Given I am logged in as "jim"
  When I follow "Support Board"
    And I follow "Open Code Tickets (Known Issues)"
  Then I should not see "Code Ticket #6"
    But I should see "Code Ticket #1 (0) fix the roof"
    And I should see "Code Ticket #2 (0) save the world"
    And I should see "Code Ticket #3 (2) repeal DADA"
    And I should see "Code Ticket #4 (0) build a zpm"
    And I should see "Code Ticket #5 (2) find a sentinel"

Scenario: code tickets can be sorted by votes
  Given the following code votes exist
    | code_ticket_id | vote  |
    | 1              | 3     |
    | 2              | 7     |
    | 3              | 18    |
  When I am on the home page
    And I follow "Support Board"
    And I follow "Open Code Tickets (Known Issues)"
  Then I should see "1: Code Ticket #1 (3) fix the roof"
    And I should see "2: Code Ticket #2 (7) save the world "
    And I should see "3: Code Ticket #3 (20) repeal DADA "
    And I should see "4: Code Ticket #4 (0) build a zpm "
    And I should see "5: Code Ticket #5 (2) find a sentinel "
  When I follow "Sort by vote count"
  Then I should see "3: Code Ticket #1 (3) fix the roof"
    And I should see "2: Code Ticket #2 (7) save the world "
    And I should see "1: Code Ticket #3 (20) repeal DADA "
    And I should see "5: Code Ticket #4 (0) build a zpm "
    And I should see "4: Code Ticket #5 (2) find a sentinel "

Scenario: users can (un)monitor open code tickets
  Given I am logged in as "jim"
    And I am on the page for code ticket 1
    And I press "Watch this ticket"
  Then 0 email should be delivered to "jim@ao3.org"
  When "sam" comments on code ticket 1
  Then 1 email should be delivered to "jim@ao3.org"
    And all emails have been delivered
  When I click the first link in the email
  Then I should see "sam (volunteer) wrote: foo bar"
  # clicking links in email in capybara looses your session
  Given I am logged in as "jim"
    And I am on the page for code ticket 1
  When I press "Don't watch this ticket"
    And "sam" comments on code ticket 1
  Then 0 emails should be delivered to "jim@ao3.org"

Scenario: users can (un)monitor worked code tickets
  Given I am logged in as "jim"
    And I am on the page for code ticket 2
    And I press "Watch this ticket"
  Then 0 email should be delivered to "jim@ao3.org"
  When "blair" comments on code ticket 2
  Then 1 email should be delivered to "jim@ao3.org"
    And all emails have been delivered
  When I click the first link in the email
  Then I should see "blair (volunteer) wrote: foo bar"
  # clicking links in email in capybara looses your session
  Given I am logged in as "jim"
    And I am on the page for code ticket 2
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

Scenario: creating a code ticket from a support ticket should enter referring url in url
  When I am logged in as "sam"
    And I am on the page for support ticket 8
  Then I should not see "referring url: /users/dean"
    And I should not see "Take"
  And I follow "view ticket as support volunteer"
  Then I should see "referring url: /users/dean"
  When I press "Create new code ticket"
    And I am on the page for the last code ticket
  Then I should see "url: /users/dean"

Scenario: creating a code ticket from a support ticket should enter user agent in browser
  When I am logged in as "blair"
    And I am on the page for support ticket 1
  Then I should see "user agent: Mozilla/5.0"
  When I press "Create new code ticket"
    And I am on the page for the last code ticket
  Then I should see "browser: Mozilla/5.0"

Scenario: creating a new code ticket should have somewhere to enter the browser and url
  When I am logged in as "blair"
    And I follow "Support Board"
    And I follow "New Code Ticket"
    And I fill in "Summary" with "something is wrong"
    And I fill in "Url" with "/tags"
    And I fill in "Browser" with "IE6"
    And I press "Create Code ticket"
  Then I should see "Code ticket created"
    And I should see "url: /tags"
    And I should see "browser: IE6"

Scenario: volunteers can steel a code ticket
  When I am logged in as "blair"
    And I am on sam's user page
    And I follow "My Open Code Tickets"
    And I follow "Code Ticket #2"
  When I press "Steal"
    Then I should see "Status: taken by blair"
  And 1 email should be delivered to "sam@ao3.org"
    And the email should contain "has been stolen by"
    And the email should contain "blair"

