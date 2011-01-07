Feature: volunteers working with code tickets

#TODO
Scenario: creating a code ticket from a support ticket should enter agent url in browser
Scenario: creating a new code ticket should have somewhere to enter the browser

Scenario: support identities don't have to be unique, but taken tickets should be correct
  Given a volunteer exists with login: "rodney", id: 1
    And a volunteer exists with login: "hermione", id: 2
  When "rodney" has a support identity "oracle"
    And "hermione" has a support identity "oracle"
    And a code ticket exists with id: 1
    And a code ticket exists with id: 2
  When "rodney" takes code ticket 1
    And "hermione" takes code ticket 2
  When I am on rodney's user page
    And I follow "My Open Code Tickets"
  Then I should see "Code Ticket #1"
    But I should not see "Code Ticket #2"
  When I am on hermione's user page
    And I follow "My Open Code Tickets"
  Then I should not see "Code Ticket #1"
    But I should see "Code Ticket #2"

Scenario: identities don't have to be unique, but closed tickets should be correct
  Given a volunteer exists with login: "rodney", id: 1
    And a volunteer exists with login: "hermione", id: 2
  When "rodney" has a support identity "oracle"
    And "hermione" has a support identity "oracle"
    And a code ticket exists with id: 1
    And a code ticket exists with id: 2
  When "rodney" resolves code ticket 1
    And "hermione" resolves code ticket 2
  When I am on rodney's user page
    And I follow "Closed Code Tickets"
  Then I should see "Code Ticket #1"
    But I should not see "Code Ticket #2"
  When I am on hermione's user page
    And I follow "Closed Code Tickets"
  Then I should not see "Code Ticket #1"
    But I should see "Code Ticket #2"

Scenario: volunteers can close a code ticket as a dupe
  Given a code ticket exists with summary: "original", id: 1
    And a code ticket exists with summary: "dupe", id: 2
  When I am logged in as volunteer "oracle"
    And I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #2"
    And I select "1" from "Code Ticket"
    And I press "Dupe"
  Then I should see "Status: closed as duplicate by oracle Code Ticket #1"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
  Then I should see "Code Ticket #1"
    But I should not see "Code Ticket #2"
  When I follow "Support Board"
    And I follow "Closed Code Tickets"
  Then I should see "Code Ticket #2"
  When I follow "oracle"
    And I follow "Closed Code Tickets"
  Then I should see "Code Ticket #2"

# TODO
Scenario: closing a ticket as a dupe should move its watchers
Scenario: closing a ticket as a dupe should move its votes
Scenario: closing a ticket as a dupe should move its support tickets
Scenario: closing a ticket as a dupe should merge its browser info

Scenario: volunteers can close a code ticket by rejecting it
  Given a code ticket exists with summary: "original", id: 1
  When I am logged in as volunteer "oracle"
    And I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
    And I fill in "reason" with "no longer reproducible"
    And I press "Reject"
  Then I should see "Status: closed by oracle"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
  Then I should not see "Code Ticket #1"
  When I follow "Support Board"
    And I follow "Closed Code Tickets"
  Then I should see "Code Ticket #1"
  When I follow "oracle"
    And I follow "Closed Code Tickets"
  Then I should see "Code Ticket #1"

Scenario: volunteers can re-open a closed code ticket
  Given a code ticket exists with summary: "original", id: 1
  When I am logged in as volunteer "oracle"
    And "oracle" resolves code ticket 1
    And I follow "Support Board"
    And I follow "Closed Code Tickets"
    And I follow "Code Ticket #1"
  When I fill in "reason" with "oops, that didn't fix it"
    And I press "Reopen"
  Then I should see "Status: open"

Scenario: volunteers can steel a code ticket
  Given a volunteer exists with login: "rodney"
    And a code ticket exists with id: 1
  When "rodney" takes code ticket 1
    Then 1 email should be delivered to "rodney@ao3.org"
    And all emails have been delivered
  When I am logged in as volunteer "hermione"
    And I am on rodney's user page
    And I follow "My Open Code Tickets"
    And I follow "Code Ticket #1"
  When I press "Steal"
    Then I should see "Status: taken by hermione"
  And 1 email should be delivered to "rodney@ao3.org"
    And the email should contain "has been stolen by"
    And the email should contain "hermione"

# TODO
Scenario: putting "closes issue #" in the commit message should transition to committed
Scenario: linking to a commit on github should transition to committed
Scenario: code tickets can be sorted by votes
Scenario: committing a code ticket closes its associated support tickets
