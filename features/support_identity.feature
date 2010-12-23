Feature: User's have support identities

Scenario: no support identity before visiting the support board
  Given a user exists with login: "sam"
  When I am on sam's user page
  Then I should not see "Support tickets opened by sam"

Scenario: automatic official identity when support volunteer
  Given a volunteer exists with login: "sam"
  When I am on sam's user page
  Then I should see "Support tickets opened by sam"
    And I should see "Support Tickets in progress"

Scenario: automatic unofficial identity when visit open support ticket
  Given I am logged in as "sam"
    And I follow "Open a New Support Ticket"
  When I am on sam's user page
  Then I should see "Support tickets opened by sam"
    But I should not see "Support Tickets in progress"

Scenario: automatic unofficial identity when visit support ticket
  Given I am logged in as "sam"
    And a support ticket exists with id: 1
  When I am on the first support ticket page
  Then I am on sam's user page
  Then I should see "Support tickets opened by sam"
    But I should not see "Support Tickets in progress"

Scenario: automatic unofficial identity when visit code ticket
  Given I am logged in as "sam"
    And a code ticket exists with id: 1
  When I am on the first code ticket page
  Then I am on sam's user page
  Then I should see "Support tickets opened by sam"
    But I should not see "Support Tickets in progress"
