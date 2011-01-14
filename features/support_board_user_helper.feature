Feature: the support board as seen by logged in users when helping

Scenario: users can't access private tickets
  Given I am logged in as "dean"
  When I am on the page for support ticket 2
  Then I should see "Sorry, you don't have permission"
  When I am on the page for support ticket 4
  Then I should see "Sorry, you don't have permission"

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

Scenario: users can comment on unowned tickets and those comments can be chosen as resolutions, which they get credit for
  Given I am logged in as "dean"
  When I am on the page for support ticket 8
    And I fill in "Details" with "where do you think?"
    And I press "Add details"
  Then I should see "dean wrote: where do you think?"
  When I am logged in as "sam"
  When I am on the page for support ticket 8
    When I select "dean wrote" from "Support Detail"
    And I press "This answer resolves my issue"
  Then I should see "Status: closed by owner"
    And I should see "dean wrote (accepted): where do you think"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #8"
  When I am logged out
    And I am on dean's user page
  Then I should see "Support tickets commented on by dean (1 accepted)"

Scenario: users cannot comment on owned tickets.
  Given I am logged in as "jim"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #3"
  When I am on the page for support ticket 3
  Then I should see "Status: taken by sam"
  And I should not see "Details"

Scenario: link to support tickets they've commented on, publicly visible
  Given I am logged in as "dean"
  When I am on the page for support ticket 8
    And I fill in "Details" with "where do you think?"
    And I press "Add details"
  When I am logged out
    And I am on dean's user page
    And I follow "Support tickets commented on by dean"
    And I follow "Support Ticket #8"
  Then I should see "dean wrote: where do you think?"

Scenario: link to code tickets they've commented on, publicly visible
  Given I am logged in as "dean"
  When I am on the page for code ticket 1
    And I fill in "Details" with "don't you dare go up on the roof, sam!"
    And I press "Add details"
  When I am logged out
    And I am on dean's user page
    And I follow "Code tickets commented on by dean"
    And I follow "Code Ticket #1"
  Then I should see "dean wrote: don't you dare go up on the roof, sam!"

Scenario: links to support tickets they're watching, private
  Given I am logged in as "jim"
  When I am on the page for support ticket 1
    And I press "Watch this ticket"
  When I follow "jim"
    And I follow "Support tickets I am watching"
    Then I should see "Support Ticket #1"
  When I am logged out
    And I am on jim's user page
  Then I should not see "Support tickets I am watching"

Scenario: links to code tickets they're watching, private
  Given I am logged in as "jim"
  When I am on the page for code ticket 1
    And I press "Watch this ticket"
  When I follow "jim"
    And I follow "Code tickets I am watching"
    Then I should see "Code Ticket #1"
  When I am logged out
    And I am on jim's user page
  Then I should not see "Code tickets I am watching"

