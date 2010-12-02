Feature: User Authentication

  Scenario: Logged out
    Given an activated user exists with login "sam"
    When I am on sam's user page
    Then I should see "sam's page"
      And I should see "Log in"
      And I should not see "Log out"
