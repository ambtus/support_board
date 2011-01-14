Feature: the support board as seen by logged in support admins

Scenario: support admins can post drafts which will show up on the FAQ page
  When I am logged in as "bofh"
  When I am on the support page
    And I follow "Frequently Asked Questions"
  Then I should not see "why we don't have enough ZPMs"
  When I am on the support page
    And I follow "FAQs waiting for comments"
    And I follow "why we don't have enough ZPMs"
    And I press "Post"
  When I am on the support page
    And I follow "Frequently Asked Questions"
  Then I should see "why we don't have enough ZPMs"

Scenario: support admins can unpost drafts which will be removed from the FAQ page
  When I am logged in as "bofh"
  When I am on the support page
    And I follow "Frequently Asked Questions"
    And I follow "where to find salt"
    And I fill in "Reason" with "needs more work"
    And I press "Reopen for comments"
  When I am on the support page
    And I follow "Frequently Asked Questions"
  Then I should not see "where to find salt"
  When I am on the support page
    And I follow "FAQs waiting for comments"
  Then I should see "where to find salt"

Scenario: when a draft FAQ is marked posted, the comments are no longer visible, but aren't destroyed
  When I am logged in as "john"
  When I am on the support page
    And I follow "FAQs waiting for comments"
    And I follow "why we don't have enough ZPMs"
    And I fill in "Details" with "please include"
    And I press "Add details"
  When I am logged in as "sam"
  When I am on the support page
    And I follow "FAQs waiting for comments"
    And I follow "why we don't have enough ZPMs"
    And I fill in "Details" with "don't forget"
    And I press "Add details"
  When I am logged in as "rodney"
  When I am on the support page
    And I follow "FAQs waiting for comments"
    And I follow "why we don't have enough ZPMs"
  Then I should see "john wrote: please include"
    And I should see "sam (volunteer) wrote: don't forget"
  When I press "Post"
  Then I should see "why we don't have enough ZPMs"
    But I should not see "john wrote: please include"
    And I should not see "sam (volunteer) wrote: don't forget"
  When I fill in "Reason" with "Oops, wrong one"
    And I press "Reopen for comments"
  Then I should see "john wrote: please include"
    And I should see "sam (volunteer) wrote: don't forget"

Scenario: admin's can mark an admin ticket admin resolved, volunteers can reopen it
  When I am logged in as "sam"
    And I go to the page for support ticket 1
    And I press "Needs admin attention"
  When I am logged in as "bofh"
    And I am on the support page
    And I follow "Support tickets requiring Admin attention"
    And I follow "Support Ticket #1"
    And I fill in "Resolution" with "resent activation code"
  When I press "Resolve"
  Then I should see "Status: closed by bofh"
  When I am on the support page
    And I follow "Support tickets requiring Admin attention"
  Then I should not see "Support Ticket #1"
  When I am logged in as "sam"
    And I am on the support page
    And I follow "Closed Support Tickets"
    And I follow "Support Ticket #1"
    And I fill in "Reason" with "still didn't work, may be a bug"
  When I press "Reopen"
  Then I should see "Status: open"
  When I am on the support page
    And I follow "Support tickets requiring Admin attention"
  Then I should not see "Support Ticket #1"
  When I am on the support page
    And I follow "Open Support Tickets"
  Then I should see "Support Ticket #1"

Scenario: admin's can mark open tickets admin resolved
  When I am logged in as "bofh"
    And I am on the support page
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I fill in "Resolution" with "no longer an issue"
  When I press "Resolve"
  Then I should see "Status: closed by bofh"

Scenario: stage all the committed tickets
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

Scenario: deploy all the verified code tickets and attach a draft release note
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

Scenario: support admins can edit release notes which have been posted
  When I am logged in as "bofh"
    And I am on the support page
    And I follow "Release Notes"
    And I follow "1.0"
  When I follow "Edit"
    And I fill in "Release" with "1.0.1"
    And I fill in "Content" with "some stuff"
    And I press "Update Release note"
  Then I should see "Release: 1.0.1"
    And I should see "some stuff"
  When I am logged in as "sam"
    And I am on the support page
    And I follow "Release Notes"
    And I follow "1.0"
  Then I should see "some stuff"
    But I should not see "Edit"

Scenario: support admins (only - privacy issues) can see the authenticity_token, browser agent and originating IP
  When I am logged in as "bofh"
    And I am on the page for support ticket 1
  Then I should see "some problem"
    And I should see "authenticity token: 123456"
    And I should see "user agent: Mozilla/5.0"
    And I should see "remote IP: 72.14.204.103"

Scenario: transition to committed manually by linking to a code commit
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
  When I fill in "reason" with "lusers don't deserve help"
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
