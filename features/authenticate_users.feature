Feature: User Authentication

  Scenario: Log in
    Given an activated user exists with login "sam"
    When I am on sam's user page
    Then I should see "sam's page"
    When I fill in "User name" with "sam"
      And I fill in "Password" with "secret"
      And I press "Log in"
    Then I should see "Hi, sam!"

  Scenario: Log out
    Given I am logged in as "sam"
    Then I should see "Hi, sam!"
    When I follow "Log out"
    Then I should see "Bye, sam!"
