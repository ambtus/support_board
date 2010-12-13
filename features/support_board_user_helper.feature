Feature: the support board as seen by logged in users when helping

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

Scenario: Making a ticket private should remove notifications from user helpers
  Given a user exists with login: "troubled", id: 1
    And a user exists with login: "curious", id: 2
    And a user exists with login: "helper", id: 3
    And a volunteer exists with login: "oracle", id: 4
  And a support ticket exists with user_id: 1
  When I am logged in as "curious"
    And I go to the first support ticket page
  When I check "Turn on notifications"
    And I press "Update Support ticket"
  Then I should see "Turn off notifications"
    And 0 emails should be delivered
  When "helper" responds to support ticket 1
  Then 1 emails should be delivered to "curious@ao3.org"
    And 1 emails should be delivered to "troubled@ao3.org"
    And all emails have been delivered
  When I am logged in as "troubled"
  When I go to the first support ticket page
    And I check "Private. (Ticket will only be visible to owner and official Support volunteers. This cannot be undone.)"
    And I press "Update Support ticket"
  Then I should see "Access: Private"
    And 1 emails should be delivered to "troubled@ao3.org"
    But 0 emails should be delivered to "curious@ao3.org"
    And all emails have been delivered
  When I am logged in as "curious"
  When I go to the first support ticket page
    Then I should not see "public ticket by troubled"
    But I should see "Sorry, you don't have permission"
  When "oracle" responds to support ticket 1
    Then 1 emails should be delivered to "troubled@ao3.org"
    But 0 emails should be delivered to "curious@ao3.org"

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

Scenario: users should get acknowledgement for every response they leave which resolves a support ticket.
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

