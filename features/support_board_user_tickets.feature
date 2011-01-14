Feature: the support board as seen by logged in users for support tickets

Scenario: user defaults for opening a new ticket
  Given I am logged in as "dean"
  When I follow "Open a New Support Ticket"
  When I press "Create Support ticket"
  Then I should not see "Email does not seem to be a valid address."
    But I should see "Summary can't be blank"
    And I should not see "Details can't be blank"
  When I fill in "Summary" with "Archive is very slow"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Summary: Archive is very slow"
    And I should not see "User: dean"
  And 1 email should be delivered to "dean@ao3.org"

Scenario: users should receive 1 initial notification
  Given I am logged in as "dean"
  When I follow "Open a New Support Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I fill in "Details" with "For example, this page took forever to load"
    And I press "Create Support ticket"
  Then 1 email should be delivered to "dean@ao3.org"

Scenario: users should receive 1 notification for each update and each change
  Given all emails have been delivered
  When "sam" comments on support ticket 3
  Then 1 email should be delivered to "dean@ao3.org"
    And all emails have been delivered
  When "rodney" links support ticket 3 to code ticket 1
  Then 1 email should be delivered to "dean@ao3.org"
    And all emails have been delivered
  When I am logged in as "sam"
    And I am on the page for support ticket 3
    And I fill in "Reason" with "faq, not code ticket, rodney"
    And I press "Reopen"
  Then 1 email should be delivered to "dean@ao3.org"
    And all emails have been delivered
  When "sam" links support ticket 3 to faq 1
  Then 1 email should be delivered to "dean@ao3.org"

# TODO
Scenario: users should not receive notifications for private details

Scenario: users can create private support tickets
  Given I am logged in as "dean"
  When I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Why are there no results when I search for wattersports?"
    And I check "Private. (Ticket will only be visible to owner and official Support volunteers. This cannot be undone.)"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Summary: Why are there no results when I search for wattersports?"
    And I should see "Access: Private"
    And 1 email should be delivered to "dean@ao3.org"
  When I am logged in as "sam"
    And I am on the support page
  When I follow "Open Support Tickets"
    Then I should see "Why are there no results"
  When I am logged out
    And I am on the support page
  Then I should not see "Open Support Tickets"
  When I am on the page for the last support ticket
  Then I should see "Sorry, you don't have permission"
  When I am logged in as "jim"
    And I am on the support page
  When I follow "Open Support Tickets"
    Then I should not see "Why are there no results"
  When I am on the page for the last support ticket
  Then I should see "Sorry, you don't have permission"

Scenario: users can choose to have their name displayed during creation, when they comment their login will be shown
  Given I am logged in as "dean"
  When I follow "Open a New Support Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I fill in "Details" with "For example"
    And I check "Display my user name"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Summary: Archive is very slow"
    And I should see "dean wrote: For example"
    And I should see "User: dean"

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

Scenario: users can create support tickets with no notifications
  Given I am logged in as "jim"
  When I follow "Open a New Support Ticket"
  And I check "Don't send me email notifications about this ticket"
    And I fill in "Summary" with "Please stop sending me notifications"
  When I press "Create Support ticket"
  Then 0 emails should be delivered to "jim@ao3.org"

Scenario: users can (un)resolve their support tickets
  Given I am logged in as "dean"
  And I am on the page for support ticket 3
  And I select "dean wrote" from "Support Detail"
    And I press "This answer resolves my issue"
  Then I should see "Status: closed by owner"
    And I should see "dean wrote (accepted): and the holy water"
  When I fill in "Reason" with "oops. clicked wrong button"
    And I press "Reopen"
  Then I should see "Status: open"
    And I should see "dean wrote: and the holy water"

Scenario: users can turn notifications on and off their own tickets. change in notifications shouldn't trigger email.
  When I am logged in as "dean"
  And I am on the page for support ticket 3
    And I fill in "Details" with "sam, are you around?"
    And I press "Add details"
  Then I should see "dean wrote: sam, are you around?"
    And 1 email should be delivered to "dean@ao3.org"
    And all emails have been delivered
  When I am logged in as "dean"
  And I am on the page for support ticket 3
  When I press "Don't watch this ticket"
    Then 0 emails should be delivered to "dean@ao3.org"
  When "sam" comments on support ticket 3
    Then 0 emails should be delivered to "dean@ao3.org"
  When I press "Watch this ticket"
    Then 0 emails should be delivered to "dean@ao3.org"
  When "sam" comments on support ticket 3
    Then 1 emails should be delivered to "dean@ao3.org"

