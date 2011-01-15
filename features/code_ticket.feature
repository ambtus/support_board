Feature: code ticket features outside the normal cycle

Scenario: creating a new code ticket from scratch should have somewhere to enter the browser and url
  When I am logged in as "blair"
    And I follow "Support Board"
    And I follow "create new code ticket"
    And I fill in "Summary" with "something is wrong"
    And I fill in "Url" with "/tags"
    And I fill in "Browser" with "IE6"
    And I press "Create Code ticket"
  Then I should see "Code ticket created"
    And I should see "url: /tags"
    And I should see "browser: IE6"

Scenario: support admins can close a code ticket by rejecting it
  When I am logged in as "bofh"
    And I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
  When I fill in "reason" with "will not fix"
    And I press "Reject"
  Then I should see "Status: closed by bofh"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
  Then I should not see "Code Ticket #1"
  When I follow "Support Board"
    And I follow "closed" within "#code_tickets"
  Then I should see "Code Ticket #1"
  When I am on the support page
    And I follow "closed" within "#code_tickets"
  Then I should see "Code Ticket #1"

Scenario: volunteers can't close a code ticket by rejecting it
  When I am logged in as "blair"
    And I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
  Then I should not see "reason"

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
    And I follow "closed" within "#code_tickets"
  Then I should see "Code Ticket #2"
  When I am on the support page
    And I follow "closed" within "#code_tickets"
  Then I should see "Code Ticket #2"
