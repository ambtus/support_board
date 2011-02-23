Feature: email notifications

Scenario: guests should receive email notification on creation
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  Then 1 email should be delivered to "guest@ao3.org"

Scenario: guests email notifications should have a link with authentication code
  When "dean" comments on support ticket 1
  And I am logged out
  Then 1 email should be delivered to "guest@ao3.org"
  When I click the first link in the email
    And I fill in "content" with "i have more information"
    And I press "Add details"
  Then I should see "ticket owner wrote: i have more information"

Scenario: guests can toggle notifications for individual tickets
  When I am on the home page
    And I follow "Support Board"
    And I fill in "email" with "guest@ao3.org"
    And I press "Send me access links to my support tickets"
  Then 1 email should be delivered to "guest@ao3.org"
    And all emails have been delivered
  When I am logged out
    And I click the first link in the email
    And I press "Don't watch this ticket"
    And "sam" comments on support ticket 1
  Then 0 emails should be delivered to "guest@ao3.org"

  # turning off notifications for one shouldn't affect the other
  When "sam" comments on support ticket 2
  Then 1 emails should be delivered to "guest@ao3.org"

Scenario: users can (un)monitor public tickets
  Given I am logged in as "dean"
  When I am on the page for support ticket 1
    And I press "Watch this ticket"
  Then 0 email should be delivered to "dean@ao3.org"
  When "sam" comments on support ticket 1
  Then 1 email should be delivered to "dean@ao3.org"
    And all emails have been delivered
  When I press "Don't watch this ticket"
  When "sam" comments on support ticket 1
  Then 0 emails should be delivered to "dean@ao3.org"

Scenario: users should receive only 1 initial notification even with an initial detail
  Given I am logged in as "dean"
  When I follow "Open a New Support Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I fill in "content" with "For example, this page took forever to load"
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

Scenario: users can create support tickets with no notifications
  Given I am logged in as "jim"
  When I follow "Open a New Support Ticket"
  And I check "Don't send me email notifications about this ticket"
    And I fill in "Summary" with "Please stop sending me notifications"
  When I press "Create Support ticket"
  Then 0 emails should be delivered to "jim@ao3.org"

Scenario: users can turn notifications on and off their own tickets. change in notifications shouldn't trigger email.
  When I am logged in as "dean"
  And I am on the page for support ticket 3
    And I fill in "content" with "sam, are you around?"
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

Scenario: volunteers can send email to another volunteer asking them to take a ticket
  When I am logged in as "blair"
    And I am on the page for support ticket 1
    Then I should see "[open]"
  When I select "sam" from "support_identity_id"
    And I press "Send request to take"
  Then 1 email should be delivered to "sam@ao3.org"
    And the email should contain "Please consider taking"
    And the email should contain "Support Ticket #1"
    And the email should contain "Thank you,<br />\nblair"
  When I click the first link in the email
  Then I should see "[open]"
    And I should see "some problem"

# TODO
Scenario: volunteers can send email to an admin asking them to post a faq

Scenario: users can (un)monitor open code tickets
  Given I am logged in as "jim"
    And I am on the page for code ticket 1
    And I press "Watch this ticket"
  Then 0 email should be delivered to "jim@ao3.org"
  When "sam" comments on code ticket 1
  Then 1 email should be delivered to "jim@ao3.org"
    And all emails have been delivered
  When I click the first link in the email
  Then I should see "sam (volunteer) wrote: foo bar"
  # clicking links in email in capybara looses your session
  Given I am logged in as "jim"
    And I am on the page for code ticket 1
  When I press "Don't watch this ticket"
    And "sam" comments on code ticket 1
  Then 0 emails should be delivered to "jim@ao3.org"

Scenario: users can (un)monitor worked code tickets
  Given I am logged in as "jim"
    And I am on the page for code ticket 2
    And I press "Watch this ticket"
  Then 0 email should be delivered to "jim@ao3.org"
  When "blair" comments on code ticket 2
  Then 1 email should be delivered to "jim@ao3.org"
    And all emails have been delivered
  When I click the first link in the email
  Then I should see "blair (volunteer) wrote: foo bar"
  # clicking links in email in capybara looses your session
  Given I am logged in as "jim"
    And I am on the page for code ticket 2
  When I press "Don't watch this ticket"
    And "blair" comments on code ticket 2
  Then 0 emails should be delivered to "jim@ao3.org"

Scenario: volunteers can steel a code ticket
  When I am logged in as "blair"
    And I am on the support page
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #2"
  When I press "Steal"
    Then I should see "[taken by blair]"
  And 1 email should be delivered to "sam@ao3.org"
    And the email should contain "has been stolen by"
    And the email should contain "blair"

Scenario: volunteers can mark a support ticket spam/ham, which doesn't send notifications
  When I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Mark as spam"
  Then 0 emails should be delivered to "guest@ao3.org"
  When I follow "Support Board"
    And I follow "spam"
    And I follow "Support Ticket #1"
    And I press "Mark as ham"
  Then I should see "[open]"
    And 0 emails should be delivered to "guest@ao3.org"
  When I follow "Support Board"
    And I follow "spam"
  Then I should not see "Support Ticket #1"

