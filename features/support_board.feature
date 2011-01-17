Feature: the support board is where you start and can find all related information

Scenario: guests can enter an email address to have authorized links re-sent
  When I am on the home page
    And I follow "Support Board"
    And I fill in "email" with "guest@ao3.org"
    And I press "Send me access links to my support tickets"
  Then 1 email should be delivered to "guest@ao3.org"
    And I should see "Email sent"
    And the email should contain "Support Ticket #1"
    And the email should contain "some problem"
    And the email should contain "Support Ticket #2"
    And the email should contain "a personal problem"

Scenario: if there are no tickets, the guest should be told
  When I am on the home page
    And I follow "Support Board"
    And I fill in "email" with "noob@ao3.org"
    And I press "Send me access links to my support tickets"
  Then 0 emails should be delivered
    And I should see "Sorry, no support tickets found for noob@ao3.org"

Scenario: guests can view public support tickets, but not comment
  When I am on the support page
    And I follow "Support Tickets"
    And I follow "Support Ticket #1"
  Then I should see "some problem"
    But I should not see "Details:"

Scenario: can find support tickets a user has commented
  When I am on the home page
    And I follow "Support Board"
    And I follow "Support Tickets"
  Then I should see "Support Ticket #3"
    And I should see "Support Ticket #8"
  When I fill in "With comments by" with "dean"
    And I press "Filter"
  Then I should not see "Support Ticket #8"
  When I follow "Support Ticket #3"
  Then I should see "dean wrote: and the holy water"

Scenario: can find all taken support tickets, and then filter by name
  When I am on the home page
    And I follow "Support Board"
    And I follow "Support Tickets"
    And I select "taken" from "Status"
    And I press "Filter"
  Then I should see "Support Ticket #3"
    And I should see "Support Ticket #9"
    But I should not see "Support Ticket #8"
  When I select "sam" from "Owned by"
    And I press "Filter"
  Then I should not see "Support Ticket #9"
    And I follow "Support Ticket #3"
  Then I should see "Status: taken by sam"

Scenario: can find support tickets waiting for a fix, and then filter by the volunteer who created the link
  When I am logged in as "blair"
    And I am on the home page
    And I follow "Support Board"
    And I follow "Support Tickets"
    And I select "waiting" from "Status"
    And I press "Filter"
  Then I should see "Support Ticket #4"
    And I should see "Support Ticket #7"
  When I select "blair" from "Owned by"
    And I press "Filter"
  Then I should not see "Support Ticket #4"
  When I follow "Support Ticket #7"
  Then I should see "Status: waiting for a code fix "
    And I should see "blair (volunteer): unowned -> waiting (5)"

Scenario: can find support tickets answered with a faq, and then filter by the volunteer who created the link
  When I am logged in as "blair"
    And I am on the home page
    And I follow "Support Board"
    And I follow "Support Tickets"
    And I select "closed" from "Status"
    And I press "Filter"
  Then I should see "Support Ticket #5"
    And I should see "Support Ticket #6"
  When I select "rodney" from "Owned by"
    And I press "Filter"
  Then I should not see "Support Ticket #6"
  When I follow "Support Ticket #5"
  Then I should see "Status: closed by rodney"

Scenario: guests can view open code tickets, but not vote or comment
  When I am on the page for code ticket 1
  Then I should see "Status: open"
  But I should not see "Vote up"
    And I should not see "Details:"

Scenario: users can view open code tickets, and vote and comment
  When I am logged in as "dean"
    And I am on the page for code ticket 1
  Then I should see "Status: open"
    And I should see "Votes: 1"
  When I press "Vote up"
    Then I should see "Votes: 2"
  When I fill in "Details" with "would be great if"
    And I press "Add details"
  Then I should see "dean wrote: would be great if"

Scenario: guests can view in progress code tickets, but not vote or comment
  When I am on the page for code ticket 2
  Then I should see "Status: taken"
  But I should not see "Vote up"
    And I should not see "Details:"

Scenario: users can view taken code tickets, and vote but not comment
  When I am logged in as "john"
    And I am on the page for code ticket 2
  Then I should see "Status: taken by sam"
    Then I should see "Votes: 4"
    But I should not see "Details:"
  When I press "Vote up"
    Then I should see "Votes: 5"

Scenario: guests can view closed code tickets, but not vote or comment
  When I am on the page for code ticket 6
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
  When I am on the home page
  When I follow "Support Board"
    And I follow "Open Code Tickets (Known Issues)"
  Then I should not see "Code Ticket #6"
    But I should see "1: Code Ticket #1 (1) [unowned] fix the roof"
    And I should see "2: Code Ticket #2 (4) [taken] save the world"
    And I should see "3: Code Ticket #3 (5) [verified] repeal DADT"
    And I should see "4: Code Ticket #4 (0) [staged] build a zpm"
    And I should see "5: Code Ticket #5 (2) [committed] find a sentinel"
    And I should see "6: Code Ticket #7 (3) [unowned] tag page broken in ie6"

Scenario: code tickets can be sorted by votes
  When I am on the home page
    And I follow "Support Board"
    And I follow "Open Code Tickets (Known Issues)"
  When I follow "Sort by vote count"
  Then I should see "5: Code Ticket #1 (1) [unowned] fix the roof"
    And I should see "2: Code Ticket #2 (4) [taken] save the world"
    And I should see "1: Code Ticket #3 (5) [verified] repeal DADT"
    And I should see "6: Code Ticket #4 (0) [staged] build a zpm"
    And I should see "4: Code Ticket #5 (2) [committed] find a sentinel"
    And I should see "3: Code Ticket #7 (3) [unowned] tag page broken in ie6"

Scenario: can find code tickets a user has commented on
  When I am on the home page
    And I follow "Support Board"
    And I follow "Open Code Tickets"
    And I fill in "With comments by" with "jim"
    And I press "Filter"
  Then I should not see "Code Ticket #4"
    And I follow "Code Ticket #5"
  Then I should see "jim wrote: what's a sentinel?"

Scenario: can't find code tickets a user has commented on without a user
  When I am on the home page
    And I follow "Support Board"
    And I follow "Code Tickets"
    And I fill in "With comments by" with "nobody"
    And I press "Filter"
  Then I should see "Please check your spelling"

Scenario: link to code tickets they've commented on, public
  Given "jim" comments on code ticket 1
  When I am on the support page
    And I follow "Open Code Tickets"
    And I fill in "With comments by" with "jim"
    And I press "Filter"
  Then I should see "Code Ticket #1"
    And I should see "Code Ticket #5"
    But I should not see "Code Ticket #2"


