Feature: the support board as seen by logged in users

Scenario: users can't access private tickets even with a direct link
  Given the following support tickets exist
    | summary                           | private | id |
    | private support ticket            | true    |  1 |
  Given I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I go to the first support ticket page
  Then I should see "Sorry, you don't have permission"

Scenario: users can (un)monitor public tickets
  Given the following support tickets exist
    | summary                           | private | id |
    | publicly visible support ticket   | false   | 1  |
    And the following activated users exist
    | login    | password | email            |
    | troubled | secret   | troubled@ao3.org |
  And I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I check "Turn on notifications"
    And I press "Update Support ticket"
  Then 1 email should be delivered to "troubled@ao3.org"
    And all emails have been delivered
  When a support volunteer responds to support ticket 1
  Then 1 email should be delivered to "troubled@ao3.org"
  When I click the first link in the email
    And I check "Turn off notifications"
    And I press "Update Support ticket"
    And all emails have been delivered
  When a support volunteer responds to support ticket 1
  Then 0 emails should be delivered to "troubled@ao3.org"

Scenario: users can comment on unowned tickets and those comments can be chosen as resolutions
  Given the following activated user exists
    | login    | password | id |
    | confused | secret   | 1  |
  Given the following support tickets exist
    | summary                           | private | user_id  | id |
    | publicly visible support ticket   | false   | 1        | 1  |
  Given I am logged in as "helper"
  When I follow "Support"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
  When I fill in "Add details" with "I think you just need to go to your profile and click..."
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "helper wrote: I think you"
  When I am logged out
    And I am logged in as "confused"
  When I go to the first support ticket page
  Then I should see "Status: Open"
  When I check "This answer resolves my issue"
    And I press "Update Support ticket"
  Then I should see "Status: Resolved"
  When I follow "Support"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"

Scenario: users cannot comment on owned tickets.
  Given the following activated support volunteer exists
    | login    | password | id |
    | oracle   | secret   | 1  |
  Given the following support tickets exist
    | summary                           | id |
    | publicly visible support ticket   | 1  |
  Given I am logged in as "oracle"
  When I follow "Support"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Take"
  When I am logged out
  And I am logged in as "helper"
  When I follow "Support"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I go to the first support ticket page
  Then I should see "support volunteer oracle"
  And I should not see "Add details"

Scenario: users don't need to provide an email address to open a ticket and their name is not automatically displayed, and they should receive notifications by default
  Given I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open a New Ticket"
  When I press "Create Support ticket"
  Then I should not see "Email does not seem to be a valid address."
    And I should see "Summary can't be blank"
  When I fill in "Summary" with "Archive is very slow"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Category: Uncategorized"
    And I should see "Summary: Archive is very slow"
    And I should not see "User: troubled"
  And 1 email should be delivered to "troubled@ao3.org"

Scenario: users should receive 1 initial notification (skip the update notification if the first update is by the owner)
  Given I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open a New Ticket"
  When I press "Create Support ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Category: Uncategorized"
    And I should see "Summary: Archive is very slow"
    And I should not see "User: troubled"
  And 1 email should be delivered to "troubled@ao3.org"
    And all emails have been delivered
  When I fill in "Add details" with "Never mind, I just found out my whole network is slow"
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "Never mind"
  And 0 emails should be delivered to "guest@ao3.org"

Scenario: users can create private support tickets
  Given I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open a New Ticket"
    And I fill in "Summary" with "Why are there no results when I search for wattersports?"
    And I check "Private. (Ticket will only be visible to official Support volunteers. This cannot be undone.)"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Summary: Why are there no results when I search for wattersports?"
    And I should see "Access: Private"
    And 1 email should be delivered to "troubled@ao3.org"

Scenario: guests can create support tickets with no initial notifications
  Given I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open a New Ticket"
  And I check "Don't send me email notifications about this ticket"
    And I fill in "Summary" with "Please stop sending me notifications"
  When I press "Create Support ticket"
  Then 0 emails should be delivered to "troubled@ao3.org"

Scenario: users can choose to have their name displayed during creation
  Given I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open a New Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I check "Display my user name"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Category: Uncategorized"
    And I should see "Summary: Archive is very slow"
    And I should see "User: troubled"

Scenario: users can (un)hide their name after creation
  Given I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open a New Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I check "Display my user name"
    And I press "Create Support ticket"
    And I should see "User: troubled"
  When I uncheck "Display my user name"
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should not see "User: troubled"
  When I check "Display my user name"
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "User: troubled"

Scenario: user's tickets should be available from their user page
  Given the following activated user exists
    | login     | id |
    | troubled  | 1  |
    | tricksy   | 2  |
  And the following activated support volunteer exists
    | login    | id |
    | oracle   | 3  |
  And the following support tickets exist
    | summary                      | id | private | display_user_name | user_id | email         |
    | publicly ticket without name | 1  | false   | false             | 1       |               |
    | private ticket without name  | 2  | true    | false             | 1       |               |
    | public ticket with name      | 3  | false   | true              | 1       |               |
    | private ticket with name     | 4  | true    | true              | 1       |               |
    | public ticket by another     | 5  | false   | true              | 2       |               |
    | public ticket by a guest     | 6  | false   | false             |         | guest@ao3.org |
  When I am on troubled's user page
    And I follow "Support tickets opened by troubled"
  Then I should see "Support Ticket #3"
    But I should not see "Support Ticket #1"
    But I should not see "Support Ticket #2"
    But I should not see "Support Ticket #4"
    And I should not see "Support Ticket #5"
    And I should not see "Support Ticket #6"
  When I am logged in as "oracle"
    And I am on troubled's user page
    And I follow "Support tickets opened by troubled"
  Then I should see "Support Ticket #3"
    And I should see "Support Ticket #4"
    But I should not see "Support Ticket #1"
    But I should not see "Support Ticket #2"
    And I should not see "Support Ticket #5"
    And I should not see "Support Ticket #6"
  When I am logged in as "troubled"
    And I am on troubled's user page
    And I follow "Support tickets opened by troubled"
  Then I should see "Support Ticket #3"
    And I should see "Support Ticket #4"
    And I should see "Support Ticket #1"
    And I should see "Support Ticket #2"
    But I should not see "Support Ticket #5"
    But I should not see "Support Ticket #6"
