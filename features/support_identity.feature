Feature: User's have support identities

Scenario: no support identity before visiting the support board
  Given a user exists with login: "sam"
  When I am on sam's user page
  Then I should not see "Support info for sam"

Scenario: automatic official identity when support volunteer
  Given a volunteer exists with login: "sam"
  When I am on sam's user page
  Then I should see "Support info for sam"

Scenario: automatic unofficial identity when visit new support ticket page
  Given I am logged in as "sam"
    And I follow "Open a New Support Ticket"
  When I am on sam's user page
  Then I should see "Support info for sam"

Scenario: automatic unofficial identity when comment on a support ticket
  Given I am logged in as "sam"
    And a support ticket exists with id: 1
  When I am on the first support ticket page
    And I fill in "Details" with "something"
    And I press "Add details"
  When I am on sam's user page
  Then I should see "Support info for sam"

Scenario: automatic unofficial identity when comment on a code ticket
  Given I am logged in as "sam"
    And a code ticket exists with id: 1
  When I am on the first code ticket page
    And I fill in "Details" with "something"
    And I press "Add details"
  When I am on sam's user page
  Then I should see "Support info for sam"

Scenario: automatic unofficial identity when watch a support ticket
  Given I am logged in as "sam"
    And a support ticket exists with id: 1
  When I am on the first support ticket page
    And I press "Watch this ticket"
  When I am on sam's user page
  Then I should see "Support info for sam"

Scenario: automatic unofficial identity when watch a code ticket
  Given I am logged in as "sam"
    And a code ticket exists with id: 1
  When I am on the first code ticket page
    And I press "Watch this ticket"
  When I am on sam's user page
  Then I should see "Support info for sam"
