Feature: the support board as seen by logged in volunteers for support tickets

Scenario: support board volunteers can access and take private tickets
  Given the following support tickets exist
    | summary                           | private | id |
    | private support ticket            | true    |  9 |
  Given I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #9"
  Then I should see "Details"
  When I press "Take"
  Then I should see "Status: taken by blair"
    And I should see "Access: Private"

Scenario: support board volunteers can untake tickets.
  Given I am logged in as "sam"
    And I am on the page for support ticket 3
  Then I should see "Status: taken by sam"
  When I fill in "Reason" with "the world can save itself"
    When I press "Reopen"
  Then I should see "Status: open"

Scenario: volunteers can steel a support ticket
  When I am logged in as "blair"
    And I am on sam's user page
    And I follow "Taken Support Tickets"
    And I follow "Support Ticket #3"
  Then I should see "Status: taken by sam"
  When I press "Steal"
    Then I should see "Status: taken by blair"
  And 1 email should be delivered to "sam@ao3.org"
    And the email should contain "has been stolen by"
    And the email should contain "blair"

Scenario: support board volunteers can comment on owned tickets.
  When I am logged in as "blair"
    And I am on sam's user page
    And I follow "Taken Support Tickets"
    And I follow "Support Ticket #3"
    When I fill in "Details" with "do you need help?"
      And I press "Add details"
    Then I should see "blair (volunteer) wrote: do you need help?"

Scenario: support board volunteers can make tickets private, but not public again
  When I am logged in as "blair"
    And I am on the page for support ticket 1
  Then I should see "Ticket will only be visible to"
    And I press "Make private"
  Then I should see "Access: Private"
    And I should not see "Ticket will only be visible to"

Scenario: private user support tickets can't be made public by volunteers
  When I am logged in as "blair"
    And I am on the page for support ticket 5
  Then I should see "Access: Private"
    And I should not see "Ticket will only be visible to"

Scenario: by default, when a volunteer comments, their comments are flagged as by support
  Given I am logged in as "blair"
    And I am on the page for support ticket 7
    And I fill in "Details" with "some very interesting things"
    And I press "Add details"
  Then I should see "blair (volunteer) wrote"

Scenario: when a volunteer comments on an open ticket, they can chose to do so as a regular user
  Given I am logged in as "blair"
    And I am on the page for support ticket 1
    And I fill in "Details" with "some very interesting things"
    And I uncheck "Official response?"
    And I press "Add details"
  Then I should see "blair wrote"
    And I should not see "blair (volunteer) wrote"

Scenario: taken support tickets should be available from the volunteer's page
  When I am on sam's user page
    And I follow "Taken Support Tickets"
  Then I should see "Support Ticket #3"
    And I should see "where's the salt?"

Scenario: waiting support tickets should be available from the volunteer's page
  When I am on blair's user page
    And I follow "Waiting Support Tickets"
  Then I should see "Support Ticket #7"
    And I should see "where can I find a guide"

Scenario: answered support tickets should be available from the volunteer's page
  When I am on blair's user page
    And I follow "Answered Support Tickets"
  Then I should not see "Support Ticket #6"
    And I should not see "what's wrong with me?"
  When I am logged in as "sam"
    And I am on blair's user page
    And I follow "Answered Support Tickets"
  Then I should see "Support Ticket #6"
    And I should see "what's wrong with me?"

Scenario: support identities don't have to be unique, but support tickets should belong to the correct user
  When "rodney" has a support identity "oracle"
    And "bofh" has a support identity "oracle"
  When "rodney" takes support ticket 1
    And "bofh" takes support ticket 8
  When I am on rodney's user page
    And I follow "Taken Support Tickets"
  Then I should see "Support Ticket #1"
    But I should not see "Support Ticket #8"
  When I am on bofh's user page
    And I follow "Taken Support Tickets"
  Then I should not see "Support Ticket #1"
    But I should see "Support Ticket #8"

Scenario: visibility on the comment board
  Given the following support tickets exist
    | summary               | id  | email         | user_id | display_user_name | private |
    | You guys rock!        | 11  | happy@ao3.org |         | false             | false   |
    | thanks for fixing it  | 12  | happy@ao3.org |         | false             | true    |
    | I like the archive    | 13  |               | 1       | false             | false   |
    | I'm leaving fandom!   | 14  |               | 2       | true              | false   |
    | thank you for helping | 15  |               | 3       | true              | true    |
  When "blair" posts support ticket 11
    And "rodney" posts support ticket 12
    And "blair" posts support ticket 13
    And "rodney" posts support ticket 14
    And "bofh" posts support ticket 15

  # logged out
  When I am logged out
    And I follow "Support Board"
    And I follow "Comments"
  Then I should not see "Support Ticket #"
  But I should see "You guys rock!"
    And I should see "I like the archive"
    And I should see "I'm leaving fandom!"
    And I should see "dean"
    And I should see "A guest"
  But I should not see "happy@ao3.org"
    And I should not see "john"
    And I should not see "newbie"
    And I should not see "thanks for fixing it"
    And I should not see "thank you for helping"

  # logged in as regular user
  When I am logged in as "dean"
    And I follow "Support Board"
    And I follow "Comments"
  Then I should not see "Support Ticket #"
  But I should see "You guys rock!"
    And I should see "I like the archive"
    And I should see "I'm leaving fandom!"
    And I should see "dean"
  But I should not see "happy@ao3.org"
    And I should not see "john"
    And I should not see "newbie"
    And I should not see "thanks for fixing it"
    And I should not see "thank you for helping"
  When I follow "#1"
    Then I should not see "Details"

  When I am logged in as "sam"
    And I follow "Support Board"
    And I follow "Comments"
  Then I should see "You guys rock!"
    And I should see "thanks for fixing it"
    And I should see "I like the archive"
    And I should see "I'm leaving fandom!"
    And I should see "thank you for helping"
    And I should see "john"
    And I should see "dean"
  But I should not see "happy@ao3.org"
    And I should not see "newbie"
  When I follow "#11"
    Then I should see "Details"
  When I fill in "Reason" with "not a comment"
    And I press "Reopen"
  Then I should see "Details"
  When I follow "Support Board"
    And I follow "Comments"
  Then I should not see "You guys rock!"

Scenario: support volunteers (only - possible privacy issues) can see the referring URL
  When I am on the page for support ticket 8
  Then I should see "where are you, dean?"
    But I should not see "referring url: /users/dean"
  When I am logged in as "blair"
    And I am on the page for support ticket 8
  Then I should see "where are you, dean?"
    And I should see "referring url: /users/dean"
