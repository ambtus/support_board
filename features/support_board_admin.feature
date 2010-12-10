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

Scenario: support admins can post drafts which will show up on the FAQ page
  Given an archive faq exists with position: 1, title: "some question", posted: false
  When I am logged in as support admin "incharge"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should not see "1: some question"
    And I am on the first archive faq page
  And I press "Post"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should see "1: some question"

Scenario: support admins can unpost drafts which will be removed from the FAQ page
  Given an archive faq exists with position: 1, title: "some question", posted: true
  When I am logged in as support admin "incharge"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should see "1: some question"
    And I am on the first archive faq page
  And I press "Unpost"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should not see "1: some question"
