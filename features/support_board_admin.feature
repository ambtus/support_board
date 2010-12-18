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
    And I should see "in progress"
    And I should see "Spam"
    And I should see "Resolved"

Scenario: support admins can post drafts which will show up on the FAQ page
  Given a faq exists with position: 1, title: "some question", posted: false
  When I am logged in as support admin "incharge"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should not see "1: some question"
  When I am on the first faq page
    And I press "Post"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should see "1: some question"

Scenario: support admins can unpost drafts which will be removed from the FAQ page
  Given a faq exists with position: 1, title: "some question", posted: true
  When I am logged in as support admin "incharge"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should see "1: some question"
    And I am on the first faq page
  And I press "Unpost"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should not see "1: some question"

Scenario: when a draft FAQ is marked posted, the comments are no longer visible.
  Given a faq exists with position: 1, posted: false
  When I am logged in as "helpful"
    And I am on the first faq page
    And I fill in "Add comment" with "please include"
    And I press "Update Faq"
  Then I should see "helpful wrote: please include"
  When I am logged in as volunteer "oracle"
    And I am on the first faq page
    And I fill in "Add comment" with "don't forget"
    And I press "Update Faq"
  Then I should see "Support volunteer oracle wrote: don't forget"
  When I am logged in as support admin "incharge"
    And I am on the first faq page
    And I press "Post"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should see "1: faq 1"
    But I should not see "helpful wrote: please include"
    And I should not see "Support volunteer oracle wrote: don't forget"

Scenario: admin's can mark an admin ticket admin resolved
  Given a support ticket exists with summary: "needs admin", id: 1
  When I am logged in as volunteer "oracle"
    And I go to the first support ticket page
    And I press "Needs Admin Attention"
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I follow "Support tickets requiring Admin attention"
    And I follow "Support Ticket #1"
  When I press "Admin Resolved"
  Then I should see "Status: Resolved by incharge"
  When I follow "Support Board"
    And I follow "Support tickets requiring Admin attention"
  Then I should not see "Support Ticket #1"
  When I am logged in as support admin "newchair"
    And I follow "Support Board"
    And I follow "Resolved Support Tickets"
    And I follow "Support Ticket #1"
  When I press "Unresolve"
  Then I should see "Status: In progress by newchair"
  When I follow "Support Board"
    And I follow "Support tickets requiring Admin attention"
  Then I should see "Support Ticket #1"

Scenario: admin's can mark any ticket admin resolved
  Given a support ticket exists with summary: "something random", id: 1
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
  When I press "Admin Resolved"
  Then I should see "Status: Resolved by incharge"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Support tickets requiring Admin attention"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Resolved Support Tickets"
  Then I should see "Support Ticket #1"

