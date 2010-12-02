Feature: User Authentication

  Scenario: Logged out
    Given a user exists with login: "sam"
    When I am on sam's user page
      Then I should see "Log in"
      Then I should not see "Log out"
