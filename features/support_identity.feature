Feature: User's have support identities

Scenario: no identity
  Given a user exists with login: "sam"
  When I am on sam's user page
  Then I should not see "Support tickets opened by sam"

Scenario: automatic official identity when support volunteer
  Given a volunteer exists with login: "sam"
  When I am on sam's user page
  Then I should see "Support tickets opened by sam"
    And I should see "Support Tickets in progress"

Scenario: automatic unofficial identity when open ticket
  Given I am logged in as "sam"
    And I follow "Open a New Support Ticket"
  When I am on sam's user page
  Then I should see "Support tickets opened by sam"
    But I should not see "Support Tickets in progress"
