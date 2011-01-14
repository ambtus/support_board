Feature: the support board is where you start and can find all related information

Scenario: guests can view public tickets if they have a link but they can't comment on them so they don't see a link from the support board
  When I am on the support page
    Then I should not see "Open Support Tickets"
  When I am on the page for support ticket 1
  Then I should see "some problem"
    But I should not see "Details:"

Scenario: guests can enter an email address to have authorized links re-sent
  When I am on the home page
    And I follow "Support Board"
    And I fill in "email" with "guest@ao3.org"
    And I press "Send me access links to my support tickets"
  Then 1 email should be delivered to "guest@ao3.org"
    And I should see "Email sent"
    And the email should contain "Support Ticket #1"
    And the email should contain "some problem"
    And the email should contain "Support Ticket #2"
    And the email should contain "a personal problem"

Scenario: if there are no tickets, the guest should be told
  When I am on the home page
    And I follow "Support Board"
    And I fill in "email" with "noob@ao3.org"
    And I press "Send me access links to my support tickets"
  Then 0 emails should be delivered
    And I should see "Sorry, no support tickets found for noob@ao3.org"

Scenario: link to support tickets users have commented on is publicly visible
  Given I am logged in as "dean"
  When I am on the page for support ticket 8
    And I fill in "Details" with "where do you think?"
    And I press "Add details"
  When I am logged out
    And I am on dean's user page
    And I follow "Support tickets commented on by dean"
    And I follow "Support Ticket #8"
  Then I should see "dean wrote: where do you think?"

Scenario: link to code tickets users have commented on is publicly visible
  Given I am logged in as "dean"
  When I am on the page for code ticket 1
    And I fill in "Details" with "don't you dare go up on the roof, sam!"
    And I press "Add details"
  When I am logged out
    And I am on dean's user page
    And I follow "Code tickets commented on by dean"
    And I follow "Code Ticket #1"
  Then I should see "dean wrote: don't you dare go up on the roof, sam!"

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

