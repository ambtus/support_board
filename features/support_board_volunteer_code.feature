Feature: volunteers working with code tickets

Scenario: support identities don't have to be unique, but code tickets should belong to the correct user
  When "rodney" has a support identity "oracle"
    And "blair" has a support identity "oracle"
  When I am on rodney's user page
    And I follow "My Open Code Tickets"
  Then I should see "Code Ticket #3"
    But I should not see "Code Ticket #5"
  When I follow "Code Ticket #3"
    Then I should see "verified by oracle"
  When I am on blair's user page
    And I follow "My Open Code Tickets"
  Then I should see "Code Ticket #5"
    But I should not see "Code Ticket #3"
  When I follow "Code Ticket #5"
    Then I should see "committed by oracle"

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

Scenario: volunteers can close a code ticket as a dupe
  When I am logged in as "sam"
    And I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #2"
    And I select "1" from "Code Ticket"
    And I press "Dupe"
  Then I should see "Status: closed as duplicate by sam Code Ticket #1"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
  Then I should see "Code Ticket #1"
    But I should not see "Code Ticket #2"
  When I follow "Support Board"
    And I follow "Closed Code Tickets"
  Then I should see "Code Ticket #2"
  When I follow "sam"
    And I follow "My Closed Code Tickets"
  Then I should see "Code Ticket #2"

Scenario: volunteers can't close a code ticket by rejecting it
  When I am logged in as "blair"
    And I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
  Then I should not see "reason"

Scenario: volunteers can re-open a closed code ticket
  When I am logged in as "blair"
    And I follow "Support Board"
    And I follow "Closed Code Tickets"
    And I follow "Code Ticket #6"
  When I fill in "reason" with "try again"
    And I press "Reopen"
  Then I should see "Status: open"
  When I follow "Support Board"
    And I follow "Closed Code Tickets"
  Then I should not see "Code Ticket #6"

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

Scenario: volunteers can create new release notes
  When I am logged in as "blair"
    And I follow "Support Board"
    And I follow "New Release Note"
    And I fill in "Release" with "0.8.4.7"
    And I fill in "Content" with "bug fix release"
    And I press "Create Release note"
  Then I should see "Release: 0.8.4.7"
    And I should see "bug fix release"
  When I follow "Edit"
    And I fill in "Release" with "0.8.4.8"
    And I press "Update Release note"
  Then I should see "Release: 0.8.4.8"

