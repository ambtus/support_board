Feature: the support board as seen by logged in users for support tickets

Scenario: what users should (not) see
  Given I am logged in as "someone"
  When I follow "Support Board"
  Then I should see "Open a New Support Ticket"
    And I should see "Comments"
    And I should see "Frequently Asked Questions"
    And I should see "Known Issues"
    And I should see "Coming Soon"
    And I should see "Release Notes"
    And I should see "Open Support Tickets"
    And I should see "Open Code Tickets"
  # since they aren't volunteers
  But I should not see "Admin attention"
    And I should not see "Claimed"
    And I should not see "Spam"
    And I should not see "Resolved"

Scenario: users can't access private tickets even with a direct link
  Given a support ticket exists with private: true
  Given I am logged in as "troubled"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I go to the first support ticket page
  Then I should see "Sorry, you don't have permission"

Scenario: users can (un)monitor public tickets
  Given a support ticket exists with id: 1
  When I am logged in as "troubled"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I check "Turn on notifications"
    And I press "Update Support ticket"
  Then 0 email should be delivered to "troubled@ao3.org"
  When a volunteer responds to support ticket 1
  Then 1 email should be delivered to "troubled@ao3.org"
    And all emails have been delivered
  When I check "Turn off notifications"
    And I press "Update Support ticket"
  When a volunteer responds to support ticket 1
  Then 0 emails should be delivered to "troubled@ao3.org"

Scenario: users can comment on unowned tickets and those comments can be chosen as resolutions
  Given a user exists with login: "troubled", id: 1
  Given a support ticket exist with id: 1, user_id: 1
  Given I am logged in as "helper"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
  When I fill in "Add details" with "I think you ..."
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "helper wrote: I think you"
  When I am logged out
    And I am logged in as "troubled"
  When I go to the first support ticket page
  Then I should see "Status: Open"
  When I check "This answer resolves my issue"
    And I press "Update Support ticket"
  Then I should see "Status: Owner resolved"
    And I should see "Answered by helper: I think you"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"

Scenario: users can comment on unowned tickets with any pseud, with the default pseud selected automatically
  Given a user exists with login: "helper", id: 1
    And a user exists with login: "troubled", id: 2
    And a pseud exists with user_id: 1, name: "alfa"
    And a pseud exists with user_id: 1, name: "charlie", is_default: true
  Given I am logged in as "troubled"
  Given a support ticket exists with user_id: 2
  Given I am logged in as "helper"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
  When I fill in "Add details" with "I think you ..."
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "charlie wrote: I think you"
  When I fill in "Add details" with "Or you could ..."
    And I select "alfa" from "Pseud"
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "charlie wrote: I think you"
    And I should see "alfa wrote: Or you could"
  When I fill in "Add details" with "Or perhaps ..."
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "charlie wrote: I think you"
    And I should see "alfa wrote: Or you could"
    And I should see "charlie wrote: Or perhaps"

Scenario: users cannot comment on owned tickets.
  Given a support ticket exists with id: 1
  Given I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Take"
  When I am logged out
  And I am logged in as "helper"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I go to the first support ticket page
  Then I should see "Status: In progress"
  And I should not see "Add details"

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

Scenario: users can turn notifications on and off their own and other tickets. notifications shouldn't trigger email.
  Given a user exists with login: "troubled"
    And a user exists with login: "tricksy"
  And a volunteer exist with login: "oracle"
  And a support ticket exists with user_id: 2, turn_off_notifications: "1"
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
  Given the following users exist
    | login     | id |
    | troubled  | 1  |
    | tricksy   | 2  |
  And the following volunteers exist
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
  When a volunteer responds to support ticket 1
    Then 1 emails should be delivered to "tricksy@ao3.org"
    But 0 emails should be delivered to "troubled@ao3.org"

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

Scenario: link to support tickets they've commented on, publicly visible
  Given the following users exist
    | login     | id |
    | helper    | 1  |
    | troubled  | 2  |
    | tricksy   | 3  |
  And the following support tickets exist
    | summary                      | id | user_id | email         |
    | public ticket by troubled    | 1  | 2       |               |
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
  Given the following users exist
    | login     | id |
    | helper    | 1  |
    | troubled  | 2  |
    | tricksy   | 3  |
  And the following support tickets exist
    | summary                      | id | user_id | email         |
    | public ticket by troubled    | 1  | 2       |               |
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

Scenario: users should get a badge for every response they leave which resolves a support ticket.
  Given the following users exist
    | login     | id |
    | helper    | 1  |
    | troubled  | 2  |
  And the following support tickets exist
    | id | summary | user_id |
    | 1  | easy    | 2       |
    | 2  | hard    | 2       |
    | 3  | right   | 2       |
    | 4  | wrong   | 2       |
  And "helper" responds to support ticket 1
  And "helper" responds to support ticket 2
  And "helper" responds to support ticket 3
  And "helper" responds to support ticket 4
  And "troubled" accepts a response to support ticket 1
  And "troubled" accepts a response to support ticket 3
  When I am on helper's user page
    Then I should see "(2 accepted)"

Scenario: users can view posted FAQs, but not comment
  Given an archive faq exists with posted: true
  When I am on the first archive faq page
  Then I should see "faq 1"
    But I should not see "Add comment"

Scenario: users can comment on a draft FAQ
  Given an archive faq exists with posted: false
    And I am logged in as "someone"
  When I am on the first archive faq page
    And I fill in "Add comment" with "this sounds good"
    And I press "Update Archive faq"
  Then I should see "someone wrote: this sounds good"

Scenario: users can remove a link to a FAQ if they don't think it resolves their ticket
  Given I am logged in as "troubled"
  When I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer creates a faq from support ticket 1
    And I reload the page
  Then I should see "Status: Linked to FAQ by oracle"
    And I should see "1: faq 1"
  When I uncheck "linked to FAQ"
    And I press "Update Support ticket"
  Then I should see "Status: In progress"
    And I should not see "1: faq 1"
