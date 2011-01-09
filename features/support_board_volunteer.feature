Feature: the support board as seen by logged in volunteers for support tickets

Scenario: support board volunteers can access and take private tickets
  Given the following support tickets exist
    | summary                           | private | id |
    | private support ticket            | true    |  1 |
  Given I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
  Then I should see "Details"
  When I press "Take"
  Then I should see "Status: taken by oracle"
    And I should see "Access: Private"

Scenario: support board volunteers can (un)take tickets.
  Given a support ticket exists with id: 1
    And I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
  Then I should see "Status: open"
  When I press "Take"
  Then I should see "Status: taken by oracle"
  When I fill in "Reason" with "RL has buried me"
    When I press "Reopen"
  Then I should see "Status: open"

Scenario: support board volunteers can steal owned tickets.
  Given a support ticket exists with id: 1
    And a volunteer exists with login: "oracle"
    And "oracle" takes support ticket 1
  Then 1 email should be delivered to "oracle@ao3.org"
    And all emails have been delivered
  Given I am logged in as volunteer "hermione"
  When I am on oracle's user page
    And I follow "Taken Support Tickets"
    And I follow "Support Ticket #1"
    When I press "Steal"
  Then 1 email should be delivered to "oracle@ao3.org"
    And the email should contain "has been stolen by"
    And the email should contain "hermione"
  When I am logged out
    And I am on oracle's user page
    And I follow "Taken Support Tickets"
  Then I should not see "Support Ticket #1"
  When I am on hermione's user page
    And I follow "Taken Support Tickets"
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
    And I follow "Support Tickets in progress"
    Then I should see "Support Ticket #1"
  When I am on oracle's user page
    And I follow "Taken Support Tickets"
    And I follow "Support Ticket #1"
  Then I should see "Status: taken by oracle"
    And I should see "Details"

Scenario: support board volunteers can make tickets private, but not public again
  Given a support ticket exists with id: 1
  When I am logged in as volunteer "oracle"
    And I go to the first support ticket page
    And I press "Make private"
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
    And I fill in "Details" with "some very interesting things"
    And I press "Add details"
  Then I should see "oracle (volunteer) wrote"

Scenario: when a volunteer comments, they can chose to do so as a regular user
  Given a support ticket exists with id: 1
    And a volunteer exists with login: "alice"
    And "alice" has a support identity "oracle"
    And I am logged in as "alice"
    And I go to the first support ticket page
  When I fill in "Details" with "some other things"
    And I uncheck "Official response?"
    And I press "Add details"
  Then I should see "oracle wrote: some other things"
    But I should not see "oracle (volunteer) wrote"

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
    And "oracle" comments on support ticket 1
    And "oracle" takes support ticket 3
    And "oracle" takes support ticket 4
  When I am on oracle's user page
    And I follow "Taken Support Tickets"
  Then I should see "Support Ticket #1"
    But I should not see "Support Ticket #2"
    But I should see "Support Ticket #3"
    And I should see "Support Ticket #4"
  When "troubled" accepts a comment on support ticket 1
    And I reload the page
  Then I should not see "Support Ticket #1"
    And I should not see "Support Ticket #2"
    But I should see "Support Ticket #3"
    And I should see "Support Ticket #4"
  When I am logged in as "oracle"
    And I am on oracle's user page
    And I follow "Taken Support Tickets"
    And I follow "Support Ticket #4"
    And I fill in "Reason" with "sorry, no time"
    And I press "Reopen"
  When I am on oracle's user page
    And I follow "Taken Support Tickets"
  Then I should not see "Support Ticket #1"
    And I should not see "Support Ticket #2"
    But I should see "Support Ticket #3"
    And I should not see "Support Ticket #4"
  When I am logged in as "troubled"
    And I am on oracle's user page
    And I follow "Taken Support Tickets"
    And I follow "Support Ticket #3"
    And I press "Make private"
  When I am on oracle's user page
    And I follow "Taken Support Tickets"
  Then I should not see "Support Ticket #1"
    And I should not see "Support Ticket #2"
    And I should not see "Support Ticket #3"
    And I should not see "Support Ticket #4"
  When I am logged in as "hermione"
    And I am on oracle's user page
    And I follow "Taken Support Tickets"
    Then I should see "Support Ticket #3"

Scenario: support tickets which are still owned by a volunteer should be available from the user page.
  Given a user exists with login: "troubled", id: 1
  And a volunteer exists with login: "oracle", id: 2
  And a volunteer exists with login: "hermione", id: 3
  And the following support tickets exist
    | id | user_id |
    | 1  | 1       |
    | 2  |         |
    | 3  |         |
    | 4  | 1       |
    | 5  |         |
    And "oracle" takes support ticket 1
    And "oracle" comments on support ticket 1
    And "troubled" accepts a comment on support ticket 1
    And "oracle" posts support ticket 2
    And "oracle" takes support ticket 3
    And "oracle" creates a faq from support ticket 4
    And "oracle" creates a code ticket from support ticket 5
    And I am on oracle's user page
  When I follow "Answered Support Tickets"
  Then I should see "Support Ticket #4"
    But I should not see "Support Ticket #1"
    And I should not see "Support Ticket #2"
    And I should not see "Support Ticket #3"
    And I should not see "Support Ticket #5"
  When I am on oracle's user page
    And I follow "Waiting Support Tickets"
  Then I should see "Support Ticket #5"
    But I should not see "Support Ticket #1"
    And I should not see "Support Ticket #2"
    And I should not see "Support Ticket #3"
    And I should not see "Support Ticket #4"
  When I am on oracle's user page
    And I follow "Taken Support Tickets"
  Then I should see "Support Ticket #3"
    But I should not see "Support Ticket #1"
    And I should not see "Support Ticket #2"
    And I should not see "Support Ticket #4"
    And I should not see "Support Ticket #5"

Scenario: support identities don't have to be unique, but in progress tickets should be correct
  Given a volunteer exists with login: "rodney", id: 1
    And a volunteer exists with login: "hermione", id: 2
  When "rodney" has a support identity "oracle"
    And "hermione" has a support identity "oracle"
    And a support ticket exists with id: 1
    And a support ticket exists with id: 2
  When "rodney" takes support ticket 1
    And "hermione" takes support ticket 2
  When I am on rodney's user page
    And I follow "Taken Support Tickets"
  Then I should see "Support Ticket #1"
    But I should not see "Support Ticket #2"
  When I am on hermione's user page
    And I follow "Taken Support Tickets"
  Then I should not see "Support Ticket #1"
    But I should see "Support Ticket #2"

Scenario: support identities don't have to be unique, but closed tickets should be correct
  Given a volunteer exists with login: "rodney", id: 1
    And a volunteer exists with login: "hermione", id: 2
  When "rodney" has a support identity "oracle"
    And "hermione" has a support identity "oracle"
    And a support ticket exists with id: 1
    And a support ticket exists with id: 2
  When "rodney" creates a faq from support ticket 1
    And "hermione" creates a faq from support ticket 2
  When I am on rodney's user page
    And I follow "Answered Support Tickets"
  Then I should see "Support Ticket #1"
    But I should not see "Support Ticket #2"
  When I am on hermione's user page
    And I follow "Answered Support Tickets"
  Then I should not see "Support Ticket #1"
    But I should see "Support Ticket #2"

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
  When "oracle" posts support ticket 1
    And "oracle" posts support ticket 2
    And "oracle" posts support ticket 3
    And "oracle" posts support ticket 4
    And "oracle" posts support ticket 5

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
    Then I should not see "Details"

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
    Then I should see "Details"
  When I fill in "Reason" with "not a comment"
    And I press "Reopen"
  Then I should see "Details"
  When I follow "Support Board"
    And I follow "Comments"
  Then I should not see "You guys rock!"

Scenario: support volunteers (only - privacy issues) can see the referring URL
  Given I am on the home page
    And I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Archive is very slow"
  But I should not see "referring url: /"
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is hard to use"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Archive is hard to use"
  But I should not see "referring url: /support_tickets/"
  When I am logged in as support admin "incharge"
    And I am on the page for the first support ticket
  Then I should see "Archive is very slow"
    And I should see "referring url: /"
    But I should not see "referring url: /support_tickets/"
  When I am on the page for the second support ticket
  Then I should see "Archive is hard to use"
    And I should see "referring url: /support_tickets/"

