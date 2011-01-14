Feature: User's have support identities

Scenario: no support identity before visiting the support board
  When I am on newbie's user page
  Then I should not see "Support info for newbie"
    And I should not see "Taken Support Tickets"

Scenario: automatic unofficial identity when visit new support ticket page
  Given I am logged in as "newbie"
    And I follow "Open a New Support Ticket"
  When I am on newbie's user page
  Then I should see "Support info for newbie"
    But I should not see "Taken Support Tickets"

Scenario: automatic unofficial identity when comment on a support ticket
  Given I am logged in as "newbie"
  When I am on the page for support ticket 1
    And I fill in "Details" with "something"
    And I press "Add details"
  When I am on newbie's user page
  Then I should see "Support info for newbie"
    But I should not see "Taken Support Tickets"

Scenario: automatic unofficial identity when comment on a code ticket
  Given I am logged in as "newbie"
  When I am on the page for code ticket 1
    And I fill in "Details" with "something"
    And I press "Add details"
  When I am on newbie's user page
  Then I should see "Support info for newbie"
    But I should not see "Taken Support Tickets"

Scenario: automatic unofficial identity when watch a support ticket
  Given I am logged in as "newbie"
  When I am on the page for support ticket 1
    And I press "Watch this ticket"
  When I am on newbie's user page
  Then I should see "Support info for newbie"
    But I should not see "Taken Support Tickets"

Scenario: automatic unofficial identity when watch a code ticket
  Given I am logged in as "newbie"
  When I am on the page for code ticket 1
    And I press "Watch this ticket"
  When I am on newbie's user page
  Then I should see "Support info for newbie"
    But I should not see "Taken Support Tickets"

Scenario: automatic official identity when support volunteer
  When I am on sam's user page
  Then I should see "Support info for sam"
    And I should see "Taken Support Tickets"

Scenario: automatic official identity when support admin
  When I am on bofh's user page
  Then I should see "Support info for bofh"
    And I should see "Taken Support Tickets"

# TODO
Scenario: a user can claim an unowned support identity (created by a github commit)
