Feature: User Authentication

Scenario: Log in
  When I am on the home page
    And I fill in "User name" with "sam"
    And I fill in "Password" with "secret"
    And I press "Log in"
  Then I should see "Hi, sam!"

Scenario: Log out
  Given I am logged in as "sam"
  Then I should see "Hi, sam!"
  When I follow "Log out"
  Then I should see "Bye, sam!"
