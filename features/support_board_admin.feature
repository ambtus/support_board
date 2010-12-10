Feature: the support board as seen by logged in support admins

Scenario: support admin's should see the same thing that support volunteers see
  Given I am logged in as support admin "incharge"
  When I follow "Support Board"
  Then I should see "Open a New Support Ticket"
    And I should see "Comments"
    And I should see "Frequently Asked Questions"
    And I should see "Known Issues"
    And I should see "Coming Soon"
    And I should see "Release Notes"
    And I should see "Open Support Tickets"
    And I should see "Open Code Tickets"
    And I should see "Admin attention"
    And I should see "Claimed"
    And I should see "Spam"
    And I should see "Resolved"

