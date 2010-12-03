Feature: User Authentication

  Scenario: Log in
    Given an activated user exists with login "sam"
    When I am on sam's user page
    Then I should see "sam's page"
    When I fill in "User name" with "sam"
      And I fill in "Password" with "secret"
      And I press "Log in"
Then show me the page
    Then I should see "Hi, sam!"
