Feature: the support board as seen by logged in users for support tickets

Scenario: user defaults for opening a new ticket
  Given I am logged in as "troubled"
  When I follow "Open a New Support Ticket"
  When I press "Create Support ticket"
  Then I should not see "Email does not seem to be a valid address."
    But I should see "Summary can't be blank"
    And I should not see "Details can't be blank"
  When I fill in "Summary" with "Archive is very slow"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Summary: Archive is very slow"
    And I should not see "User: troubled"
  And 1 email should be delivered to "troubled@ao3.org"

Scenario: users should receive 1 initial notification and 1 for additional updates
  Given I am logged in as "troubled"
  When I follow "Open a New Support Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I fill in "Details" with "For example, this page took forever to load"
    And I press "Create Support ticket"
  Then 1 email should be delivered to "troubled@ao3.org"
    And all emails have been delivered
  When I fill in "Add details" with "Never mind, I just found out my whole network is slow"
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "Ticket owner wrote: Never mind"
  And 1 email should be delivered to "troubled@ao3.org"
    And all emails have been delivered
  When a volunteer responds to support ticket 1
  Then 1 email should be delivered to "troubled@ao3.org"
    And all emails have been delivered
  When a user responds to support ticket 1
  Then 1 email should be delivered to "troubled@ao3.org"

Scenario: users can create private support tickets
  Given I am logged in as "troubled"
  When I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Why are there no results when I search for wattersports?"
    And I check "Private. (Ticket will only be visible to owner and official Support volunteers. This cannot be undone.)"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Summary: Why are there no results when I search for wattersports?"
    And I should see "Access: Private"
    And 1 email should be delivered to "troubled@ao3.org"

Scenario: private user support tickets should be private and can't be made public
  Given a user exists with login: "troubled", id: 1
  And a volunteer exists with login: "oracle"
  And a support ticket exists with summary: "embarrassing", private: true, user_id: 1
  When I am logged out
    And I go to the first support ticket page
  Then I should see "Sorry, you don't have permission"
    And I should not see "embarrassing"
  When I am logged in as "tricksy"
    And I go to the first support ticket page
  Then I should see "Sorry, you don't have permission"
    And I should not see "embarrassing"
  When I am logged in as "oracle"
    And I go to the first support ticket page
  Then I should see "embarrassing"
  When I am logged in as "troubled"
    And I go to the first support ticket page
  Then I should see "embarrassing"
    And I should not see "Ticket will only be visible to"

Scenario: users can choose to have their name displayed during creation, when they comment their pseud will be shown
  Given I am logged in as "troubled"
  When I follow "Open a New Support Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I fill in "Details" with "For example"
    And I check "Display my user name"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Summary: Archive is very slow"
    And I should see "User: troubled"
    And I should see "troubled wrote: For example"

Scenario: if their name is displayed during creation they can use any pseud for details, with the default pseud defaulted
  Given a user exists with login: "troubled", id: 1
  Given the following pseuds exist
    | user_id | name    | is_default |
    | 1       | alfa    |            |
    | 1       | charlie | true       |
  Given I am logged in as "troubled"
  When I follow "Open a New Support Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I fill in "Details" with "For example"
    And I check "Display my user name"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Summary: Archive is very slow"
    And I should see "User: troubled"
    And I should see "charlie wrote: For example"
  When I fill in "Add details" with "Some more stuff"
    And I select "alfa" from "Pseud"
    And I press "Update Support ticket"
  Then I should see "User: troubled"
    And I should see "charlie wrote: For example"
    And I should see "alfa wrote: Some more stuff"
  When I fill in "Add details" with "Even more stuff"
    And I press "Update Support ticket"
  Then I should see "User: troubled"
    And I should see "charlie wrote: For example"
    And I should see "alfa wrote: Some more stuff"
    And I should see "charlie wrote: Even more stuff"

Scenario: users can (un)hide their name after creation
  Given I am logged in as "troubled"
  When I follow "Open a New Support Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I fill in "Details" with "For example"
    And I check "Display my user name"
    And I press "Create Support ticket"
    And I should see "User: troubled"
    And I should see "troubled wrote: For example"
  When I uncheck "Display my user name"
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should not see "User: troubled"
    And I should see "Ticket owner wrote: For example"
  When I check "Display my user name"
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "User: troubled"
    And I should see "troubled wrote: For example"

Scenario: user's tickets should be available from their user page
  Given the following users exist
    | login     | id |
    | troubled  | 1  |
    | tricksy   | 2  |
  And a volunteer exists with login: "oracle", id: 3
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

Scenario: users can create support tickets with no notifications
  Given I am logged in as "troubled"
  When I follow "Open a New Support Ticket"
  And I check "Don't send me email notifications about this ticket"
    And I fill in "Summary" with "Please stop sending me notifications"
  When I press "Create Support ticket"
  Then 0 emails should be delivered to "troubled@ao3.org"

Scenario: users can (un)resolve their support tickets
  Given I am logged in as "troubled"
  When I follow "Open a New Support Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Summary: Archive is very slow"
  When I fill in "Add details" with "Never mind, my router was broken"
    And I press "Update Support ticket"
    And I should see "Ticket owner wrote: Never mind"
    And I check "This answer resolves my issue"
    And I press "Update Support ticket"
  Then I should see "Status: Owner resolved"
    And I should see "Answered by Ticket owner: Never mind"
  When I uncheck "This answer resolves my issue"
    And I fill in "Add details" with "Router fixed, archive still slow"
    And I press "Update Support ticket"
  Then I should see "Status: Open"
  When a volunteer responds to support ticket 1
    And I reload the page
  When I check "support_ticket_support_details_attributes_2_resolved_ticket"
    And I press "Update Support ticket"
  Then I should see "Status: Owner resolved"
    And I should see "Answered by Support volunteer oracle"

Scenario: users can answer their support tickets with visible names
  Given I am logged in as "troubled"
  When I follow "Open a New Support Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I check "Display my user name"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
  When I fill in "Add details" with "Never mind, my router was broken"
    And I press "Update Support ticket"
    And I should see "troubled wrote: Never mind"
    And I check "This answer resolves my issue"
    And I press "Update Support ticket"
  Then I should see "Status: Owner resolved"
    And I should see "Answered by troubled: Never mind"

Scenario: users can turn notifications on and off their own tickets. notifications shouldn't trigger email.
  Given a user exists with login: "helper"
    And a user exists with login: "troubled"
  And a volunteer exist with login: "oracle"
  And a support ticket exists with user_id: 2, turn_off_notifications: "1"
  Then 0 emails should be delivered
  When I am logged in as "helper"
  When I go to the first support ticket page
    And I fill in "Add details" with "possible answer"
    And I press "Update Support ticket"
  Then I should see "helper wrote: possible answer"
    And 0 emails should be delivered to "troubled@ao3.org"
    And all emails have been delivered
  When I am logged in as "troubled"
  When I go to the first support ticket page
  When I check "Turn on notifications"
    And I press "Update Support ticket"
  Then I should see "Turn off notifications"
    And 0 emails should be delivered
  When I fill in "Add details" with "doesn't work, thanks anyway"
    And I press "Update Support ticket"
  Then 1 emails should be delivered to "troubled@ao3.org"

