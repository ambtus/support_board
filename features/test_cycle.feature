Feature: code tickets must go through a test cycle before they can be deployed

Scenario: admin's can transition a code ticket to committed by linking it to a code commit
  When I am logged in as "bofh"
    And I am on the support page
  When I follow "Support Tickets in progress"
    And I follow "Support Ticket #3"
    Then I should see "Status: taken by sam"
  When I am on the support page
    And I follow "Unmatched Commits"
  When I follow "1 by sam"
    And I select "save the world" from "Code Ticket"
    And I press "Match"
  Then I should be on the code commits page
    And I should not see "1 by sam"
  When I am on the support page
    And I follow "Committed Code Tickets"
    And I follow "Code Ticket #2"
    And I should see "committed by sam"
    And I should see "Commit 1 by sam no issue number"

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
    And I follow "Closed Code Tickets"
  Then I should see "Code Ticket #1"
  When I follow "bofh"
    And I follow "Closed Code Tickets"
  Then I should see "Code Ticket #1"

Scenario: volunteers can't close a code ticket by rejecting it
  When I am logged in as "blair"
    And I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
  Then I should not see "reason"

Scenario: admin's can stage committed tickets once they are all matched
  When I am logged in as "rodney"
    And I am on the support page
  Then I should see "Committed Code Tickets (1)"
    And I follow "Committed Code Tickets"
  Then I should see "Code Ticket #5"
  When I am on the support page
    Then I should see "Unmatched Commits (1)"
  When I follow "Unmatched Commits"
    And I follow "1 by sam"
    And I select "save the world" from "Code Ticket"
    And I press "Match"
  When I am on the support page
    And I press "Stage Committed Code Tickets"
  When I am on the support page
  Then I should see "Committed Code Tickets (0)"
  When I follow "Staged Code Tickets"
    Then I should see "Code Ticket #5"

Scenario: volunteers can verify staged Tickets
  When I am logged in as "sam"
    And I follow "Support Board"
    And I follow "Staged Code Tickets"
  Then I should see "Code Ticket #4 (0) build a zpm"
  When I follow "Code Ticket #4"
    And I press "Verify"
  Then I should see "Status: verified by sam"
    When I follow "Support Board"
    And I follow "Staged Code Tickets"
  Then I should not see "Code Ticket #4"

Scenario: admins can deploy the code tickets once they have all been verified and there is a draft release note
  When I am logged in as "bofh"
    And I am on the support page
  Then I should see "Staged Code Tickets (1)"
    And I should see "Verified Code Tickets (1)"
  When I follow "Staged Code Tickets"
    And I follow "Code Ticket #4"
    And I press "Verify"
  When I am on the support page
  Then I should see "Staged Code Tickets (0)"
    And I should see "Verified Code Tickets (2)"
  When I follow "Release Notes"
    Then I should not see "2.0"
  When I am on the support page
    And I follow "Draft Release Notes"
    Then I should see "2.0"
  When I am on the support page
  Then I should not see "1.0"
  When I select "2.0" from "Release note"
    And I press "Deploy Verified Code Tickets"
  Then I should see "2.0"
  When I am on the support page
  Then I should see "Staged Code Tickets (0)"
    And I should see "Verified Code Tickets (0)"

Scenario: deploying should close the waiting support tickets
  When I am logged in as "bofh"
    And I am on the support page
  Then I should see "Support Tickets waiting for Code changes (2)"
  When I follow "Support Tickets waiting for Code changes"
    And I follow "Support Ticket #4"
  Then I should see "repeal DADA"
    And I should see "Status: waiting for a code fix"
  When I am on the support page
  When I follow "Staged Code Tickets"
    And I follow "Code Ticket #4"
    And I press "Verify"
  When I am on the support page
    And I select "2.0" from "Release note"
    And I press "Deploy Verified Code Tickets"
  When I am on the support page
  When I follow "Closed Support Tickets"
    And I follow "Support Ticket #4"
    And I should see "Status: fixed in 2.0"

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

