Feature: support tickets have privacy concerns

Scenario: guests can't access private tickets even with a direct link.
  When I am on the page for support ticket 2
  Then I should see "Sorry, you don't have permission"
    And I should not see "a personal problem"

Scenario: support admins (only - privacy issues) can see the authenticity_token, browser agent and originating IP
  When I am logged in as "bofh"
    And I am on the page for support ticket 1
  Then I should see "some problem"
    And I should see "authenticity token: 123456"
    And I should see "user agent: Mozilla/5.0"
    And I should see "remote IP: 72.14.204.103"

Scenario: guests can't make their private support tickets public
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
    And I check "Private"
  When I press "Create Support ticket"
  Then I should see "Access: Private"
    But I should not see "Ticket will only be visible"

Scenario: guests can make their public support tickets private, even to users who already commented who should no longer get email
  When "jim" watches support ticket 1
    And "jim" comments on support ticket 1
  Then 1 email should be delivered to "jim@ao3.org"
  Then 1 email should be delivered to "guest@ao3.org"
    And all emails have been delivered
  When I click the first link in the email
    Then I should see "Ticket will only be visible"
  When I press "Make private"
    And I am logged in as "jim"
    And I am on the page for support ticket 1
  Then I should see "Sorry, you don't have permission"
  When "sam" comments on support ticket 1
  Then 1 email should be delivered to "guest@ao3.org"
  And 0 emails should be delivered to "jim@ao3.org"

Scenario: email to others shouldn't include the authorization
  When I am logged in as "jim"
    And I am on the page for support ticket 1
    And I press "Watch this ticket"
  When I am logged out
    And "sam" comments on support ticket 1
  Then 1 email should be delivered to "jim@ao3.org"
  When I click the first link in the email
  Then I should see "sam (volunteer) wrote"
    But I should not see "Ticket will only be visible"

Scenario: users can't access private tickets
  Given I am logged in as "dean"
  When I am on the page for support ticket 2
  Then I should see "Sorry, you don't have permission"
  When I am on the page for support ticket 4
  Then I should see "Sorry, you don't have permission"

Scenario: links to support tickets users are watching is private
  Given I am logged in as "jim"
  When I am on the page for support ticket 1
    And I press "Watch this ticket"
  When I follow "jim"
    And I follow "Support tickets I am watching"
    Then I should see "Support Ticket #1"
  When I am logged out
    And I am on jim's user page
  Then I should not see "Support tickets I am watching"

Scenario: links to code tickets users are watching is private
  Given I am logged in as "jim"
  When I am on the page for code ticket 1
    And I press "Watch this ticket"
  When I follow "jim"
    And I follow "Code tickets I am watching"
    Then I should see "Code Ticket #1"
  When I am logged out
    And I am on jim's user page
  Then I should not see "Code tickets I am watching"

Scenario: users can hide their name after creation
  Given I am logged in as "dean"
  And I am on the page for support ticket 3
  Then I should see "User: dean"
    And I should see "dean wrote: and the holy water"
  When I press "Hide my user name"
  Then I should not see "User: dean"
    And I should see "ticket owner wrote: and the holy water"

Scenario: users can unhide their name after creation
  Given I am logged in as "sam"
  And I am on the page for support ticket 8
  Then I should not see "User: sam"
    And I should see "ticket owner wrote: don't make me come looking for you!"
  When I press "Display my user name"
  Then I should see "User: sam"
    And I should see "sam wrote: don't make me come looking for you!"

Scenario: user's tickets should be available from their user page, respecting private and show user name
  Given I am logged out
  When I am on dean's user page
    And I follow "dean's open support tickets"
  Then I should see "Support Ticket #3"
  When I am on john's user page
    And I follow "john's open support tickets"
  Then I should not see "Support Ticket #4"
  When I am on john's user page
     And I follow "john's closed support tickets"
   And I should not see "Support Ticket #5"
  When I am on jim's user page
    And I follow "jim's open support tickets"
  Then I should not see "Support Ticket #7"

  Given I am logged in as "dean"
  When I am on dean's user page
    And I follow "dean's open support tickets"
  Then I should see "Support Ticket #3"
  When I am on john's user page
    And I follow "john's open support tickets"
  Then I should not see "Support Ticket #4"
  When I am on john's user page
     And I follow "john's closed support tickets"
    And I should not see "Support Ticket #5"
  When I am on jim's user page
    And I follow "jim's open support tickets"
  Then I should not see "Support Ticket #7"

  Given I am logged in as "jim"
  When I am on jim's user page
    And I follow "jim's open support tickets"
  Then I should see "Support Ticket #7"

  Given I am logged in as "john"
  When I am on john's user page
    And I follow "john's open support tickets"
  Then I should see "Support Ticket #4"
  When I am on john's user page
     And I follow "john's closed support tickets"
    And I should see "Support Ticket #5"

  Given I am logged in as "sam"
  When I am on dean's user page
    And I follow "dean's open support tickets"
  Then I should see "Support Ticket #3"
  When I am on john's user page
    And I follow "john's open support tickets"
  Then I should not see "Support Ticket #4"
  When I am on john's user page
     And I follow "john's closed support tickets"
    But I should see "Support Ticket #5"
  When I am on jim's user page
    And I follow "jim's open support tickets"
  Then I should not see "Support Ticket #7"

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

# TODO
Scenario: guests and users should not be able to see private support details
Scenario: guests and users should not receive notifications for private details

