Feature: the support board as seen by guests

Scenario: guests can browse public tickets but not update them. they can't access private tickets even with a direct link.

  Given the following support tickets exist
    | summary                           | private | email         | id |
    | private support ticket            | true    | guest@ao3.org | 1  |
    | publicly visible support ticket   | false   | guest@ao3.org | 2  |
  Given I am on the home page
  When I follow "Support"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Ticket #2"
  Then I should see "publicly visible support ticket"
    But I should not see "Add details"
  When I go to the first support ticket page
  Then I should see "Sorry, you don't have permission"

Scenario: guests can't create a support ticket without a valid email address. (we need it for spam catching, plus it would make the ticket too hard for them to access later)
  Given I am on the home page
  When I follow "Support"
    And I follow "Open a New Ticket"
  When I press "Create Support ticket"
  Then I should see "Email does not seem to be a valid address."
    And I should see "Summary can't be blank"
  When I fill in "Summary" with "Archive is very slow"
    And I press "Create Support ticket"
  Then I should see "Email does not seem to be a valid address."
  When I fill in "Email" with "bite me"
    And I press "Create Support ticket"
  Then I should see "Email does not seem to be a valid address."

Scenario: guests can create a support ticket with a valid email address which is not visible
  Given I am on the home page
  When I follow "Support"
    And I follow "Open a New Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Category: Uncategorized"
    And I should see "Summary: Archive is very slow"
  But I should not see "guest@ao3.org"

  # guests should be able to fill in more details immediately, without waiting for email confirmation
  When I fill in "Add details" with "For example, it took a minute for this page to render"
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "For example"

  # guests should receive 1 initial notification (skip the update notification if the first update is by the owner)
  And 1 email should be delivered to "guest@ao3.org"
    And all emails have been delivered

  # guests can continue to make other changes (persistent authorization)
  When I fill in "Add details" with "Never mind, I just found out my whole network is slow"
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "Never mind"
  And 1 email should be delivered to "guest@ao3.org"

Scenario: guests can create private support tickets
  Given I am on the home page
  When I follow "Support"
    And I follow "Open a New Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Why are there no results when I search for wattersports?"
    And I check "Private. (Ticket will only be visible to official Support volunteers. This cannot be undone.)"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Summary: Why are there no results when I search for wattersports?"
    And I should see "Access: Private"
    And 1 email should be delivered to "guest@ao3.org"

Scenario: guests can create support tickets with no initial notifications
  Given I am on the home page
  When I follow "Support"
    And I follow "Open a New Ticket"
  And I check "Don't send me email notifications about this ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Please stop sending me notifications"
  When I press "Create Support ticket"
  Then 0 emails should be delivered to "guest@ao3.org"

Scenario: guests can enter an email address to have authorized links re-sent and can turn on/off notifications for individual tickets
  Given the following support tickets exist
    | email         | private |
    | guest@ao3.org | false   |
    | guest@ao3.org | true    |
    And all emails have been delivered
  When I am on the home page
    And I follow "Support"
    And I fill in "email" with "guest@ao3.org"
    And I press "Send me access links to my support tickets"
  Then 1 email should be delivered to "guest@ao3.org"
    And I should see "Email sent"
    And all emails have been delivered

  When I click the first link in the email
    And I check "Turn off notifications"
    And I press "Update Support ticket"
  Then I should see "Turn on notifications"
  When a user responds to support ticket 1
  Then 0 emails should be delivered to "guest@ao3.org"

  When a support volunteer responds to support ticket 2
  Then 1 email should be delivered to "guest@ao3.org"
    And all emails have been delivered

  # I'm still on support ticket 1's page
  When I check "Turn on notifications"
    And I press "Update Support ticket"
  Then 1 email should be delivered to "guest@ao3.org"
    And all emails have been delivered

  When a support volunteer responds to support ticket 1
  Then 1 email should be delivered to "guest@ao3.org"

Scenario: if there are no tickets, the guest should be told
  Given the following support tickets exist
    | email          |
    | guest1@ao3.org |
    | guest2@ao3.org |
    And all emails have been delivered
  When I am on the home page
    And I follow "Support"
    And I fill in "email" with "guest@ao3.org"
    And I press "Send me access links to my support tickets"
  Then 0 emails should be delivered
    And I should see "Sorry, no support tickets found for guest@ao3.org"

Scenario: guests email notifications should have a link with authentication code
  Given the following support tickets exist
    | email         | private |
    | guest@ao3.org | false   |
    And all emails have been delivered
  When a support volunteer responds to support ticket 1
  Then 1 email should be delivered to "guest@ao3.org"
    And all emails have been delivered

  # email notifications should have a link with authentication code
  When I click the first link in the email
  Then I should see "Add details"

  # guests can make their support tickets private when they came in through an authorized link
  When I check "Private. (Ticket will only be visible to official Support volunteers. This cannot be undone.)"

  # guests can resolve support tickets when they came in through an authorized link
  And I check "This answer resolves my issue"

  When I press "Update Support ticket"
  Then I should see "Access: Private"
    And I should see "Status: Resolved"

  # but they can't make them public again
  But I should not see "Ticket will only be visible to official Support volunteers"

  # but they can unresolve them
  When I uncheck "This answer resolves my issue"
   And I press "Update Support ticket"
  Then I should see "Status: Open"

Scenario: can view code tickets as a guest, but not vote or respond
  Given the following code tickets exist
    | summary                                 |
    | Multichapter works give 500 to admins   |
    | OpenID broken                           |
  Given I am on the home page
  When I follow "Support"
    And I follow "Code Tickets"
  Then I should see "Multichapter works give 500 to admins"
  When I follow "OpenID broken"
  Then I should not see "Vote Up"
    And I should not see "Vote Down"
    And I should not see "Add details"
