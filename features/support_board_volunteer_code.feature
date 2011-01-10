Feature: volunteers working with code tickets

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

Scenario: creating a code ticket from a support ticket should enter referring url in url
  Given a support ticket exists with url: "/works/1523"
  When I am logged in as volunteer "oracle"
    And I am on the first support ticket page
  Then I should see "referring url: /works/1523"
  When I press "Create new code ticket"
    And I am on the page for the first code ticket
  Then I should see "url: /works/1523"

Scenario: creating a code ticket from a support ticket should enter user agent in browser
  Given a support ticket exists with user_agent: "Mozilla/5.0"
  When I am logged in as volunteer "oracle"
    And I am on the first support ticket page
  Then I should see "user agent: Mozilla/5.0"
  When I press "Create new code ticket"
    And I am on the page for the first code ticket
  Then I should see "browser: Mozilla/5.0"

Scenario: creating a new code ticket should have somewhere to enter the browser and url
  When I am logged in as volunteer "oracle"
    And I follow "Support Board"
    And I follow "New Code Ticket"
    And I fill in "Summary" with "something is wrong"
    And I fill in "Url" with "/tags"
    And I fill in "Browser" with "IE6"
    And I press "Create Code ticket"
  Then I should see "Code ticket created"
    And I should see "url: /tags"
    And I should see "browser: IE6"

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
Scenario: putting "closes issue #" in the git commit message should transition to committed
Scenario: transition to committed should require a github commit id, which should act as a link

Scenario: volunteers can create new release notes
  When I am logged in as volunteer "oracle"
    And I follow "Support Board"
    And I follow "New Release Note"
    And I fill in "Release" with "0.8.4.7"
    And I fill in "Content" with "bug fix release"
    And I press "Create Release note"
  Then I should see "Release: 0.8.4.7"
    And I should see "bug fix release"
  When I follow "Edit"
    And I fill in "Release" with "0.8.4.8"
    And I press "Update Release note"
  Then I should see "Release: 0.8.4.8"

# TODO
Scenario: volunteers can edit release notes which haven't been posted yet
