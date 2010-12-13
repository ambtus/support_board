Feature: the support board as seen by logged in volunteers for support tickets

Scenario: what volunteers should see
  Given I am logged in as volunteer "oracle"
  When I follow "Support Board"
  Then I should see "Open a New Support Ticket"
    And I should see "Comments"
    And I should see "Frequently Asked Questions"
    And I should see "Known Issues"
    And I should see "Coming Soon"
    And I should see "Release Notes"
    And I should see "Open Support Tickets"
    And I should see "Open Code Tickets"
    And I should see "Admin attention"
    And I should see "Claimed"
    And I should see "Spam"
    And I should see "Resolved"

Scenario: support board volunteers can access and take private tickets
  Given the following support tickets exist
    | summary                           | private | id |
    | private support ticket            | true    |  1 |
  Given I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
  Then I should see "Add details"
  When I press "Take"
  Then I should see "Status: In progress"
    And I should see "Access: Private"

Scenario: support board volunteers can (un)take tickets.
  Given a support ticket exists with id: 1
    And I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
  Then I should see "Status: Open"
  When I press "Take"
  Then I should see "Status: In progress"
    When I press "Untake"
  Then I should see "Status: Open"

Scenario: support board volunteers can steal owned tickets.
  Given a support ticket exists with id: 1
    And a volunteer exists with login: "oracle"
    And "oracle" takes support ticket 1
  Given I am logged in as volunteer "hermione"
  When I am on oracle's user page
    And I follow "oracle's pseuds"
    And I follow "oracle"
    And I follow "Support tickets"
    And I follow "Support Ticket #1"
    When I press "Take"
  Then 1 email should be delivered to "oracle@ao3.org"
    And the email should contain "has been stolen by"
    And the email should contain "hermione"
  When I am logged out
    And I am on oracle's user page
    And I follow "oracle's pseuds"
    And I follow "oracle"
    And I follow "Support tickets"
  Then I should not see "Support Ticket #1"
  When I am on hermione's user page
    And I follow "hermione's pseuds"
    And I follow "hermione"
    And I follow "Support tickets"
  Then I should see "Support Ticket #1"

Scenario: support board volunteers can comment on owned tickets.
  Given a support ticket exists with id: 1
    And a volunteer exists with login: "oracle"
    And "oracle" takes support ticket 1
  Given I am logged in as volunteer "hermione"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Claimed Support Tickets"
    Then I should see "Support Ticket #1"
  When I am on oracle's user page
    And I follow "oracle's pseuds"
    And I follow "oracle"
    And I follow "Support tickets"
    And I follow "Support Ticket #1"
  Then I should see "Status: In progress"
    And I should see "Add details"

Scenario: support board volunteers can make tickets private, but not public again
  Given a support ticket exists with id: 1
  When I am logged in as volunteer "oracle"
    And I go to the first support ticket page
    And I check "Private"
    And I press "Update Support ticket"
  Then I should see "Access: Private"
    And I should not see "Ticket will only be visible to"

Scenario: private user support tickets can't be made public by volunteers
  Given a user exists with login: "troubled", id: 1
  And the following support tickets exist
    | summary      | private | user_id |
    | embarrassing | true    | 1       |
  When I am logged in as volunteer "oracle"
    And I go to the first support ticket page
  Then I should see "embarrassing"
    And I should see "Access: Private"
    But I should not see "Ticket will only be visible to"

Scenario: by default, when a volunteer comments, their comments are flagged as by support
  Given a support ticket exists with id: 1
    And I am logged in as volunteer "oracle"
    And I go to the first support ticket page
    And I fill in "Add details" with "some very interesting things"
    And I press "Update Support ticket"
  Then I should see "volunteer oracle wrote"

Scenario: when a volunteer comments, they can chose to do so as a regular user
  Given a support ticket exists with id: 1
    And a volunteer exists with login: "alice"
    And "alice" has a support pseud "oracle"
    And I am logged in as "alice"
    And I go to the first support ticket page
    And I fill in "Add details" with "some official things"
    And I press "Update Support ticket"
  Then I should see "Support volunteer oracle wrote: some official things"
  When I fill in "Add details" with "some other things"
    And I select "alice" from "Pseud"
    And I press "Update Support ticket"
  Then I should see "Support volunteer oracle wrote: some official things"
    And I should see "alice wrote: some other things"
    But I should not see "Support volunteer alice wrote"

Scenario: working support tickets should be available from the user page
  Given a user exists with login: "troubled", id: 1
  And a volunteer exists with login: "oracle", id: 2
  And a volunteer exists with login: "hermione", id: 3
  And the following support tickets exist
    | id | summary | user_id |
    | 1  | easy    | 1       |
    | 2  | hard    |         |
    | 3  | right   | 1       |
    | 4  | wrong   |         |
    And "oracle" takes support ticket 1
    And "oracle" responds to support ticket 1
    And "oracle" takes support ticket 3
    And "oracle" takes support ticket 4
  When I am on oracle's user page
    And I follow "oracle's pseuds"
    And I follow "oracle"
    And I follow "Support tickets"
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
  When I am logged in as "oracle"
    And I am on oracle's user page
    And I follow "oracle's pseuds"
    And I follow "oracle" within ".pseuds"
    And I follow "Support tickets"
    And I follow "Support Ticket #4"
    And I press "Untake"
  When I am on oracle's user page
    And I follow "oracle's pseuds"
    And I follow "oracle" within ".pseuds"
    And I follow "Support tickets"
  Then I should not see "Support Ticket #1"
    And I should not see "Support Ticket #2"
    But I should see "Support Ticket #3"
    And I should not see "Support Ticket #4"
  When I am logged in as "troubled"
    And I am on oracle's user page
    And I follow "oracle's pseuds"
    And I follow "oracle" within ".pseuds"
    And I follow "Support tickets"
    And I follow "Support Ticket #3"
    And I check "Private"
    And I press "Update Support ticket"
  When I am on oracle's user page
    And I follow "oracle's pseuds"
    And I follow "oracle" within ".pseuds"
    And I follow "Support tickets"
  Then I should not see "Support Ticket #1"
    And I should not see "Support Ticket #2"
    And I should not see "Support Ticket #3"
    And I should not see "Support Ticket #4"
  When I am logged in as "hermione"
    And I am on oracle's user page
    And I follow "oracle's pseuds"
    And I follow "oracle" within ".pseuds"
    And I follow "Support tickets"
    Then I should see "Support Ticket #3"

Scenario: visibility on the comment board
  Given the following users exist
    | login        | id |
    | default      | 1  |
    | loud         | 2  |
    | private      | 3  |
  And the following support tickets exist
    | summary               | id | email         | user_id | display_user_name | private |
    | You guys rock!        | 1  | happy@ao3.org |         | false             | false   |
    | thanks for fixing it  | 2  | happy@ao3.org |         | false             | true    |
    | I like the archive    | 3  |               | 1       | false             | false   |
    | I'm leaving fandom!   | 4  |               | 2       | true              | false   |
    | thank you for helping | 5  |               | 3       | true              | true    |
  And a volunteer exists with login: "oracle"
  When "oracle" categorizes support ticket 1 as Comment
    And "oracle" categorizes support ticket 2 as Comment
    And "oracle" categorizes support ticket 3 as Comment
    And "oracle" categorizes support ticket 4 as Comment
    And "oracle" categorizes support ticket 5 as Comment

  # logged out
  When I am logged out
    And I follow "Support Board"
    And I follow "Comments"
  Then I should not see "Support Ticket #"
  But I should see "You guys rock!"
    And I should see "I like the archive"
    And I should see "I'm leaving fandom!"
    And I should see "loud"
  But I should not see "happy@ao3.org"
    And I should not see "default"
    And I should not see "private"
    And I should not see "thanks for fixing it"
    And I should not see "thank you for helping"

  # logged in as regular user
  When I am logged in as "curious"
    And I follow "Support Board"
    And I follow "Comments"
  Then I should not see "Support Ticket #"
  But I should see "You guys rock!"
    And I should see "I like the archive"
    And I should see "I'm leaving fandom!"
    And I should see "loud"
  But I should not see "happy@ao3.org"
    And I should not see "default"
    And I should not see "private"
    And I should not see "thanks for fixing it"
    And I should not see "thank you for helping"
  When I follow "#1"
    Then I should not see "Add details"

  When I am logged in as volunteer "hermione"
    And I follow "Support Board"
    And I follow "Comments"
  Then I should see "You guys rock!"
    And I should see "thanks for fixing it"
    And I should see "I like the archive"
    And I should see "I'm leaving fandom!"
    And I should see "thank you for helping"
    And I should see "loud"
    And I should see "private"
  But I should not see "happy@ao3.org"
    And I should not see "default"
  When I follow "#1"
    Then I should see "Add details"
    When I press "Needs Attention"
  Then I should see "Add details"
  When I follow "Support Board"
    And I follow "Comments"
  Then I should not see "You guys rock!"
