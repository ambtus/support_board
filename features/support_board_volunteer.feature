Feature: the support board as seen by logged in support volunteers for support tickets

Scenario: support board volunteers can access and take private tickets
  Given the following support tickets exist
    | summary                           | private | id |
    | private support ticket            | true    |  1 |
  Given I am logged in as support volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
  Then I should see "Add details"
  When I press "Take"
  Then I should see "Status: Being worked by support volunteer oracle"
    And I should see "Access: Private"

Scenario: support board volunteers can (un)take tickets.
  Given the following support tickets exist
    | summary                           | id |
    | publicly visible support ticket   | 1  |
  Given I am logged in as support volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
  Then I should see "Status: Open"
  When I press "Take"
  Then I should see "Status: Being worked by support volunteer oracle"
    When I press "Untake"
  Then I should see "Status: Open"

Scenario: support board volunteers can steal owned tickets.
  Given the following support tickets exist
    | summary                           | id |
    | publicly visible support ticket   | 1  |
    And an activated support volunteer exists with login "oracle"
    And "oracle" takes support ticket 1
  Given I am logged in as support volunteer "hermione"
  When I follow "Support Board"
    And I follow "Claimed Support Tickets"
    And I follow "Support Ticket #1"
  Then I should see "support volunteer oracle"
    When I press "Take"
  Then I should see "support volunteer hermione"
    And 1 email should be delivered to "oracle@ao3.org"
    And the email should contain "has been stolen by"
    And the email should contain "hermione"

Scenario: support board volunteers can comment on owned tickets.
  Given the following support tickets exist
    | summary                           | id |
    | publicly visible support ticket   | 1  |
    And an activated support volunteer exists with login "oracle"
    And "oracle" takes support ticket 1
  Given I am logged in as support volunteer "hermione"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Claimed Support Tickets"
    And I follow "Support Ticket #1"
  Then I should see "support volunteer oracle"
    And I should see "Add details"

Scenario: support board volunteers can make tickets private, but not public again
  Given the following support tickets exist
    | summary                           | id |
    | publicly visible support ticket   | 1  |
  When I am logged in as support volunteer "oracle"
    And I go to the first support ticket page
    And I check "Private"
    And I press "Update Support ticket"
  Then I should see "Access: Private"
    And I should not see "Ticket will only be visible to"

Scenario: private user support tickets can't be made public by volunteers
  Given the following activated user exists
    | login     | id |
    | troubled  | 1  |
  And the following support tickets exist
    | summary      | private | user_id |
    | embarrassing | true    | 1       |
  When I am logged in as support volunteer "oracle"
    And I go to the first support ticket page
  Then I should see "embarrassing"
    And I should see "Access: Private"
    But I should not see "Ticket will only be visible to"

Scenario: by default, when a support volunteer comments, their comments are flagged as by support
  Given the following support tickets exist
    | summary                           | id |
    | publicly visible support ticket   | 1  |
  Given I am logged in as support volunteer "oracle"
    And I go to the first support ticket page
    And I fill in "Add details" with "some very interesting things"
    And I press "Update Support ticket"
  Then I should see "Support volunteer oracle(SV) wrote"

Scenario: when a support volunteer comments, they can chose to do so as a regular user
  Given the following support tickets exist
    | summary                           | id |
    | publicly visible support ticket   | 1  |
  Given I am logged in as support volunteer "oracle"
    And I go to the first support ticket page
    And I fill in "Add details" with "some very interesting things"
    And I select "oracle" from "Pseud"
    And I press "Update Support ticket"
  Then I should see "oracle wrote"
    And I should not see "Support volunteer oracle"

Scenario: working support tickets should be available from the user page
  Given the following activated user exists
    | login     | id |
    | troubled  | 1  |
  And the following support tickets exist
    | id | summary | user_id |
    | 1  | easy    | 1       |
    | 2  | hard    |         |
    | 3  | right   | 1       |
    | 4  | wrong   |         |
  And an activated support volunteer exists with login "oracle"
    And "oracle" takes support ticket 1
    And "oracle" responds to support ticket 1
    And "oracle" takes support ticket 3
    And "oracle" takes support ticket 4
  When I am on oracle's user page
    And I follow "Support tickets claimed by oracle"
  Then I should see "Support Ticket #1"
    But I should not see "Support Ticket #2"
    But I should see "Support Ticket #3"
    And I should see "Support Ticket #4"
  When "troubled" accepts a response to support ticket 1
    And I reload the page
  Then I should not see "Support Ticket #1"
    And I should not see "Support Ticket #2"
    But I should see "Support Ticket #3"
    And I should see "Support Ticket #4"
  When I am logged in as support volunteer "oracle"
    And I am on oracle's user page
    And I follow "Support tickets claimed by oracle"
    And I follow "Support Ticket #4"
    And I press "Untake"
  When I am on oracle's user page
    And I follow "Support tickets claimed by oracle"
  Then I should not see "Support Ticket #1"
    And I should not see "Support Ticket #2"
    But I should see "Support Ticket #3"
    And I should not see "Support Ticket #4"
  When I am logged in as "troubled"
    And I am on oracle's user page
    And I follow "Support tickets claimed by oracle"
    And I follow "Support Ticket #3"
    And I check "Private"
    And I press "Update Support ticket"
  When I am on oracle's user page
    And I follow "Support tickets claimed by oracle"
  Then I should not see "Support Ticket #1"
    And I should not see "Support Ticket #2"
    And I should not see "Support Ticket #3"
    And I should not see "Support Ticket #4"
  When I am logged in as support volunteer "hermione"
    And I am on oracle's user page
    And I follow "Support tickets claimed by oracle"
    Then I should see "Support Ticket #3"

Scenario: support volunteers can mark a support ticket spam/ham
  Given the following support tickets exist
    | summary       | id |
    | buy viagra    | 1  |
    And all emails have been delivered
  When I am logged in as support volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Spam"
  Then 0 emails should be delivered to "guest@ao3.org"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
    When I go to the first support ticket page
    And I press "Ham"
  Then 1 emails should be delivered to "guest@ao3.org"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should see "Support Ticket #1"

Scenario: support volunteers can mark a support ticket for an Admin to resolve
  Given the following support tickets exist
    | summary       | id |
    | needs admin   | 1  |
    | question      | 2  |
  When I am logged in as support volunteer "oracle"
    And I go to the first support ticket page
    And I choose "Admin"
    And I press "Update Support ticket"
  Then I should see "Category: Admin"
  When I follow "Support Board"
    And I follow "Support tickets requiring Admin attention"
  Then I should see "Support Ticket #1"
    But I should not see "Support Ticket #2"

Scenario: support board volunteers can categorize support tickets
  Given the following support tickets exist
    | summary    | id |
    | question   | 1  |
  When I am logged in as support volunteer "oracle"
    And I go to the first support ticket page
    And I choose "Question"
    And I press "Update Support ticket"
  Then I should see "Category: Question"
  When I choose "Problem"
    And I press "Update Support ticket"
  Then I should see "Category: Problem"
  When I choose "Kudo"
    And I press "Update Support ticket"
  Then I should see "Category: Kudo"

