Feature: Admin Authentication

Scenario: Log in
  Given an activated admin exists with login "admin-sam"
  When I am on the admin_login page
  When I fill in "Admin name" with "admin-sam"
    And I fill in "Admin Password" with "secret"
    And I press "Log in as Admin"
  Then I should see "Hi, admin-sam!"

Scenario: Log out
  Given I am logged in as admin "admin-sam"
  Then I should see "Hi, admin-sam!"
  When I follow "Log out"
  Then I should see "Bye, admin-sam!"
