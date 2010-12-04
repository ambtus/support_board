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
    | summary                           | id |
    | publicly visible support ticket   | 1  |
    And the following activated users exist
    | login    | password | email            |
    | troubled | secret   | troubled@ao3.org |
  And I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I check "Turn on notifications"
    And I press "Update Support ticket"
  Then 0 email should be delivered to "troubled@ao3.org"
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
    | summary                           | user_id  | id |
    | publicly visible support ticket   | 1        | 1  |
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

Scenario: users can comment on unowned tickets with any pseud, with the default pseud selected automatically
  Given the following activated user exists
    | login     | id |
    | helper    | 1  |
    | confused  | 2  |
  Given the following pseuds exist
    | user_id | name    | is_default |
    | 1       | alfa    |            |
    | 1       | charlie | true       |
  Given I am logged in as "troubled"
  Given the following support tickets exist
    | summary                           | user_id  | id |
    | publicly visible support ticket   | 2        | 1  |
  Given I am logged in as "helper"
  When I follow "Support"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
  When I fill in "Add details" with "I think you just need to go to your profile and click..."
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "charlie wrote: I think you"
  When I fill in "Add details" with "Or you could..."
    And I select "alfa" from "Pseud"
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "charlie wrote: I think you"
    And I should see "alfa wrote: Or you could..."
  When I fill in "Add details" with "Or perhaps..."
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "charlie wrote: I think you"
    And I should see "alfa wrote: Or you could..."
    And I should see "charlie wrote: Or perhaps"

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

Scenario: user defaults for opening a new ticket
  Given I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open a New Ticket"
  When I press "Create Support ticket"
  Then I should not see "Email does not seem to be a valid address."
    But I should see "Summary can't be blank"
    And I should not see "Details can't be blank"
  When I fill in "Summary" with "Archive is very slow"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Category: Uncategorized"
    And I should see "Summary: Archive is very slow"
    And I should not see "User: troubled"
  And 1 email should be delivered to "troubled@ao3.org"

Scenario: users should receive 1 initial notification and 1 for additional updates
  Given I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open a New Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I fill in "Details" with "For example, this page took forever to load"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Category: Uncategorized"
    And I should see "Summary: Archive is very slow"
    And I should see "Ticket owner wrote: For example"
    And I should not see "User: troubled"
  And 1 email should be delivered to "troubled@ao3.org"
    And all emails have been delivered
  When I fill in "Add details" with "Never mind, I just found out my whole network is slow"
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "Ticket owner wrote: Never mind"
  And 1 email should be delivered to "troubled@ao3.org"

Scenario: users can create private support tickets
  Given I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open a New Ticket"
    And I fill in "Summary" with "Why are there no results when I search for wattersports?"
    And I check "Private. (Ticket will only be visible to owner and official Support volunteers. This cannot be undone.)"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Summary: Why are there no results when I search for wattersports?"
    And I should see "Access: Private"
    And 1 email should be delivered to "troubled@ao3.org"

Scenario: private user support tickets should be private and can't be made public
  Given the following activated user exists
    | login     | id |
    | troubled  | 1  |
  And the following activated support volunteer exists
    | login    |
    | oracle   |
  And the following support tickets exist
    | summary      | private | user_id |
    | embarrassing | true    | 1       |
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
  When I follow "Support"
    And I follow "Open a New Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I fill in "Details" with "For example"
    And I check "Display my user name"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Category: Uncategorized"
    And I should see "Summary: Archive is very slow"
    And I should see "User: troubled"
    And I should see "troubled wrote: For example"

Scenario: if their name is displayed during creation they can use any pseud for details, with the default pseud defaulted
  Given the following activated user exists
    | login     | id |
    | troubled  | 1  |
  Given the following pseuds exist
    | user_id | name    | is_default |
    | 1       | alfa    |            |
    | 1       | charlie | true       |
  Given I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open a New Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I fill in "Details" with "For example"
    And I check "Display my user name"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Category: Uncategorized"
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
  When I follow "Support"
    And I follow "Open a New Ticket"
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

Scenario: guests can create support tickets with no notifications
  Given I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open a New Ticket"
  And I check "Don't send me email notifications about this ticket"
    And I fill in "Summary" with "Please stop sending me notifications"
  When I press "Create Support ticket"
  Then 0 emails should be delivered to "troubled@ao3.org"

Scenario: guests can turn notifications on and off their own and other tickets. notifications shouldn't trigger email.
  Given the following activated users exist
    | login     | id |
    | troubled  | 1  |
    | tricksy   | 2  |
  And the following activated support volunteer exists
    | login    | id |
    | oracle   | 3  |
  And the following support tickets exist
    | summary                    | private| user_id | turn_off_notifications |
    | public ticket by tricksy   | false  | 2       | 1                      |
  Then 0 emails should be delivered
  When I am logged in as "troubled"
  When I go to the first support ticket page
  When I check "Turn on notifications"
    And I fill in "Add details" with "possible answer"
    And I press "Update Support ticket"
  Then I should see "Turn off notifications"
    And I should see "possible answer"
    And 1 emails should be delivered to "troubled@ao3.org"
    And 0 emails should be delivered to "tricksy@ao3.org"
    And all emails have been delivered
  When I am logged in as "oracle"
  When I go to the first support ticket page
    And I fill in "Add details" with "different answer"
    And I press "Update Support ticket"
  Then 1 emails should be delivered to "troubled@ao3.org"
    And 0 emails should be delivered to "tricksy@ao3.org"
    And all emails have been delivered
  When I am logged in as "tricksy"
  When I go to the first support ticket page
  When I check "Turn on notifications"
    And I press "Update Support ticket"
  Then I should see "Turn off notifications"
    And 0 emails should be delivered
  When I fill in "Add details" with "neither answer works, thanks anyway"
    And I press "Update Support ticket"
  Then 1 emails should be delivered to "troubled@ao3.org"
    And 1 emails should be delivered to "tricksy@ao3.org"

Scenario: Making a ticket private should remove notifications from non-owner/non-volunteer
  Given the following activated users exist
    | login     | id |
    | troubled  | 1  |
    | tricksy   | 2  |
  And the following activated support volunteer exists
    | login    | id |
    | oracle   | 3  |
  And the following support tickets exist
    | summary                    | user_id |
    | public ticket by tricksy   | 2       |
  When I am logged in as "troubled"
  When I go to the first support ticket page
    Then I should see "public ticket by tricksy"
  When I check "Turn on notifications"
    And I press "Update Support ticket"
  Then I should see "Turn off notifications"
    And 0 emails should be delivered
  When a user responds to support ticket 1
  Then 1 emails should be delivered to "troubled@ao3.org"
    And 1 emails should be delivered to "tricksy@ao3.org"
    And all emails have been delivered
  When I am logged in as "tricksy"
  When I go to the first support ticket page
    And I check "Private. (Ticket will only be visible to owner and official Support volunteers. This cannot be undone.)"
    And I press "Update Support ticket"
  Then I should see "Access: Private"
    And 1 emails should be delivered to "tricksy@ao3.org"
    But 0 emails should be delivered to "troubled@ao3.org"
    And all emails have been delivered
  When I am logged in as "troubled"
  When I go to the first support ticket page
    Then I should not see "public ticket by tricksy"
    But I should see "Sorry, you don't have permission"
  When a support volunteer responds to support ticket 1
    Then 1 emails should be delivered to "tricksy@ao3.org"
    But 0 emails should be delivered to "troubled@ao3.org"

Scenario: users can (un)resolve their support tickets
  Given I am logged in as "troubled"
  When I follow "Support"
    And I follow "Open a New Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I fill in "Details" with "For example"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Category: Uncategorized"
    And I should see "Summary: Archive is very slow"
    And I should not see "User: troubled"
    And I should see "Ticket owner wrote: For example"
  When I fill in "Add details" with "Never mind, my router was broken"
    And I press "Update Support ticket"
    And I check "This answer resolves my issue"
    And I press "Update Support ticket"
  Then I should see "Status: Resolved"
  When I uncheck "This answer resolves my issue"
    And I fill in "Add details" with "Router fixed, archive still slow"
    And I press "Update Support ticket"
  Then I should see "Status: Open"
  When a support volunteer responds to support ticket 1
    And I reload the page
  When I check "support_ticket_support_details_attributes_3_resolved_ticket"
    And I press "Update Support ticket"
  Then I should see "Status: Resolved"

Scenario: link to support tickets they've commented on, publicly visible
  Given the following activated users exist
    | login     | id |
    | helper    | 1  |
    | confused  | 2  |
    | tricksy   | 3  |
  And the following support tickets exist
    | summary                      | id | user_id | email         |
    | public ticket by confused    | 1  | 2       |               |
    | public ticket by tricksy     | 2  | 3       |               |
    | public ticket by helper      | 3  | 1       |               |
    | public ticket by a guest     | 4  |         | guest@ao3.org |
  And "helper" responds to support ticket 1
  And "helper" responds to support ticket 4
  When I am on helper's user page
    And I follow "Support tickets commented on by helper"
  Then I should see "Support Ticket #1"
    And I should see "Support Ticket #4"
    But I should not see "Support Ticket #2"
    And I should not see "Support Ticket #3"

Scenario: links to support tickets they're watching, private
  Given the following activated users exist
    | login     | id |
    | helper    | 1  |
    | confused  | 2  |
    | tricksy   | 3  |
  And the following support tickets exist
    | summary                      | id | user_id | email         |
    | public ticket by confused    | 1  | 2       |               |
    | public ticket by tricksy     | 2  | 3       |               |
    | public ticket by helper      | 3  | 1       |               |
    | public ticket by a guest     | 4  |         | guest@ao3.org |
  And "helper" watches support ticket 1
  And "helper" watches support ticket 2
  When I am on helper's user page
    Then I should not see "watched"
  When I am logged in as "helper"
    And I follow "helper"
    And I follow "Support tickets I am watching"
  Then I should see "Support Ticket #1"
    And I should see "Support Ticket #2"
    And I should see "Support Ticket #3"
    But I should not see "Support Ticket #4"



#          can vote up or down code tickets
#          can (un)watch code tickets
#          can't comment on code tickets which are owned
