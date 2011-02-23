Feature: code tickets

### code ticket index

Scenario: can see all open code tickets
  When I am on the home page
  When I follow "Support Board"
    And I follow "Open Code Tickets (Known Issues)"
  Then I should see "Code Ticket #5 find a sentinel [committed by blair] (2 votes)"
    And I should see "Code Ticket #4 build a zpm [waiting for verification (commited by rodney)] (0 votes)"
    And I should see "Code Ticket #3 repeal DADT [verified by sidra] (5 votes)"
    And I should see "Code Ticket #2 save the world [taken by sam] (4 votes)"
    And I should see "Code Ticket #1 fix the roof [open] (1 votes)"
  But I should not see "Code Ticket #6"
    And I should not see "Code Ticket #7"
    And I should not see "Code Ticket #8"

Scenario: code tickets can be sorted by votes
  When I am on the home page
    And I follow "Support Board"
    And I follow "Open Code Tickets (Known Issues)"
  Then I should see "Code Ticket #5" within "#0"
  When I select "highest vote" from "Sort by"
    And I press "Filter"
  Then I should see "Code Ticket #3" within "#0"

Scenario: can find code tickets a user has commented on
  When I am on the home page
    And I follow "Support Board"
    And I follow "Open Code Tickets"
    And I fill in "With comments by" with "jim"
    And I press "Filter"
  Then I should not see "Code Ticket #4"
    And I follow "Code Ticket #5"
  Then I should see "jim wrote: what's a sentinel?"

Scenario: can't find code tickets a user has commented on without a user
  When I am on the home page
    And I follow "Support Board"
    And I follow "Code Tickets"
    And I fill in "With comments by" with "nobody"
    And I press "Filter"
  Then I should see "Please check your spelling"

Scenario: link to code tickets they've commented on, public
  Given "jim" comments on code ticket 1
  When I am on the support page
    And I follow "Open Code Tickets"
    And I fill in "With comments by" with "jim"
    And I press "Filter"
  Then I should see "Code Ticket #1"
    And I should see "Code Ticket #5"
    But I should not see "Code Ticket #2"

### new code ticket

Scenario: volunteers can create a new minimal code ticket
  When I am logged in as "sam"
    And I am on the support page
    And I follow "create new code ticket"
    And I fill in "Summary" with "new code ticket"
    And I press "Create Code ticket"
  Then I should see "Code ticket created"
    And I should see "new code ticket [open] (0 votes)"

Scenario: creating a new code ticket should have somewhere to enter the browser and url
  When I am logged in as "blair"
    And I follow "Support Board"
    And I follow "create new code ticket"
    And I fill in "Summary" with "something is wrong"
    And I fill in "Url" with "/tags"
    And I fill in "Browser" with "IE6"
    And I press "Create Code ticket"
  Then I should see "Code ticket created"
    And I should see "url: /tags"
    And I should see "browser: IE6"

Scenario: creating a new code ticket should allow you to add longer details on the first screen
  When I am logged in as "sam"
    And I am on the support page
    And I follow "create new code ticket"
    And I fill in "Summary" with "new code ticket"
    And I fill in "Details" with "a bunch of stuff too long to fit in the summary"
    And I press "Create Code ticket"
  Then I should see "Code ticket created"
    And I should see "sam (volunteer) wrote: a bunch of stuff too long to fit in the summary"

Scenario: volunteers can create a new code ticket directly off of an anonymous support ticket
  When I am logged in as "blair"
  When I am on the page for support ticket 20
    And I press "Create new code ticket"
  When I press "Update Code ticket"
  Then I should see "anon is my name [open] (3 votes)"
    And I should see "Related Support tickets 20"
    And I should see "browser: Safari 5.0.3 (OS X)"
    But I should not see "url: /"

Scenario: volunteers can create a new code ticket directly off of a non-anonymous support ticket
  When I am logged in as "blair"
  When I am on the page for support ticket 8
    And I press "Create new code ticket"
    And I fill in "Browser" with ""
  When I press "Update Code ticket"
  Then I should see "where are you, dean? [open] (3 votes)"
    And I should see "Related Support tickets 8"
    And I should see "url: /users/dean"
    But I should not see "browser:"

### comments, votes and watching unowned tickets

Scenario: guests can view open code tickets
  When I am on the page for code ticket 1
  Then I should see "open"

Scenario: users can comment on unowned code tickets
  When I am logged in as "jim"
    And I am on the page for code ticket 1
    And I fill in "content" with "i have an opinion"
    And I press "Add details"
  Then I should see "jim wrote: i have an opinion"

Scenario: users can vote for unowned code tickets
  When I am logged in as "jim"
    And I am on the page for code ticket 1
  Then I should see "fix the roof [open] (1 votes)"
  When I press "Vote up"
  Then I should see "fix the roof [open] (2 votes)"

Scenario: users can watch code tickets
  When I am logged in as "jim"
    And I am on the page for code ticket 1
  Then I should see "fix the roof [open] (1 votes)"
  When I press "Watch this ticket"
    And "sam" comments on code ticket 1
  Then 1 emails should be delivered to jim@ao3.org

Scenario: volunteers can comment on unowned code tickets
  When I am logged in as "blair"
    And I am on the page for code ticket 1
    And I fill in "content" with "i have an opinion"
    And I press "Add details"
  Then I should see "blair (volunteer) wrote: i have an opinion"

Scenario: volunteers can comment privately on unowned code tickets
  When I am logged in as "blair"
    And I am on the page for code ticket 1
    And I fill in "content" with "i have an opinion"
    And I choose "private"
    And I press "Add details"
  Then I should see "blair (volunteer) wrote [private]: i have an opinion"

Scenario: volunteers can comment unofficially on unowned code tickets
  When I am logged in as "blair"
    And I am on the page for code ticket 1
    And I fill in "content" with "i have an opinion"
    And I choose "unofficial"
    And I press "Add details"
  Then I should see "blair wrote: i have an opinion"

### non typical closure

Scenario: support admins can close a code ticket by rejecting it
  When I am logged in as "sidra"
    And I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #1"
  When I fill in "reason" with "will not fix"
    And I press "Reject"
  Then I should see "closed by sidra"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
  Then I should not see "Code Ticket #1"
  When I follow "Support Board"
    And I follow "closed" within "#code_tickets"
  Then I should see "Code Ticket #1"
  When I am on the support page
    And I follow "closed" within "#code_tickets"
  Then I should see "Code Ticket #1"

Scenario: volunteers can close a code ticket as a dupe
  When I am logged in as "sam"
    And I follow "Support Board"
    And I follow "Open Code Tickets"
    And I follow "Code Ticket #2"
    And I select "fix the roof" from "code_ticket_id"
    And I press "Dupe"
  Then I should see "closed as duplicate by sam Code Ticket #1"
  When I follow "Support Board"
    And I follow "Open Code Tickets"
  Then I should see "Code Ticket #1"
    But I should not see "Code Ticket #2"
  When I follow "Support Board"
    And I follow "closed" within "#code_tickets"
  Then I should see "Code Ticket #2"
  When I am on the support page
    And I follow "closed" within "#code_tickets"
  Then I should see "Code Ticket #2"

### take a code ticket

Scenario: volunteers can take a code ticket
  When I am logged in as "blair"
    And I am on the page for code ticket 1
    And I press "Take"
  Then I should see "fix the roof [taken by blair]"

Scenario: volunteers can steal a code ticket
  When I am logged in as "blair"
    And I am on the page for code ticket 2
  Then I should see "[taken by sam]"
   And I press "Steal"
  Then I should see "[taken by blair]"

### comments, votes and watching owned tickets

Scenario: users can view taken code tickets, and vote on them
  When I am logged in as "john"
    And I am on the page for code ticket 2
  Then I should see "taken by sam"
    Then I should see "(4 votes)"
  When I press "Vote up"
    Then I should see "(5 votes)"

Scenario: users can watch code tickets
  When I am logged in as "jim"
    And I am on the page for code ticket 2
  When I press "Watch this ticket"
    And "sam" comments on code ticket 2
  Then 1 emails should be delivered to jim@ao3.org

Scenario: volunteers can comment on owned code tickets
  When I am logged in as "blair"
    And I am on the page for code ticket 2
    And I fill in "content" with "i have an opinion"
    And I press "Add details"
  Then I should see "blair (volunteer) wrote: i have an opinion"

Scenario: volunteers can comment privately on owned code tickets
  When I am logged in as "blair"
    And I am on the page for code ticket 2
    And I fill in "content" with "i have an opinion"
    And I choose "private"
    And I press "Add details"
  Then I should see "blair (volunteer) wrote [private]: i have an opinion"

### commit a code ticket

Scenario: volunteers can commit a code ticket by choosing a code commit
  When I am logged in as "blair"
    And I am on the page for code ticket 2
    And I select "this should fix it" from "code_commit_id"
    And I press "Commit"
  Then I should see "save the world [committed by sam]"
    And I should see "Code Commit #1"

Scenario: admin's can commit a code ticket from the unmatched code commits page and stage committed tickets once all commits are matched
  When I am logged in as "rodney"
    And I am on the support page
  Then I should see "committed (1)"
    And I follow "committed"
  Then I should see "Code Ticket #5"
  When I am on the support page
    Then I should see "Unmatched Commits (1)"
  When I follow "Unmatched Commits"
    And I follow "Code Commit #1"
    And I select "save the world" from "code_ticket_id"
    And I press "Match"
  When I am on the support page
    And I press "Stage Committed Code Tickets"
  When I am on the support page
  Then I should see "committed (0)"
  When I follow "staged"
    Then I should see "Code Ticket #5"
    And I should see "Code Ticket #2"

Scenario: volunteers can verify staged Tickets
  When I am logged in as "sam"
    And I follow "Support Board"
    And I follow "staged"
  Then I should see "build a zpm [waiting for verification (commited by rodney)]"
  When I follow "Code Ticket #4"
    And I press "Verify"
  Then I should see "verified by sam"

Scenario: admins can deploy the code tickets once they have all been verified and there is a draft release note
  When I am logged in as "sidra"
    And I am on the support page
  Then I should see "staged (1)"
    And I should see "verified (1)"
  When I follow "staged"
    And I follow "Code Ticket #4"
    And I press "Verify"
  When I am on the support page
  Then I should see "staged (0)"
    And I should see "verified (2)"
  When I follow "Release Notes"
    Then I should not see "2.1"
  When I am on the support page
    And I follow "drafts" within "#release_notes"
    Then I should see "2.1"
  When I am on the support page
  Then I should not see "1.0"
  When I select "2.1" from "Release note"
    And I press "Deploy Verified Code Tickets"
  Then I should see "2.1"
  When I am on the support page
  Then I should see "staged (0)"
    And I should see "verified (0)"

Scenario: deploying should close the waiting support tickets
  When I am logged in as "sidra"
    And I am on the support page
  Then I should see "waiting for code changes (2)"
  When I follow "waiting for code changes"
    And I follow "Support Ticket #4"
  Then I should see "repeal DADT"
    And I should see "waiting for a code fix"
  When I am on the support page
  When I follow "staged"
    And I follow "Code Ticket #4"
    And I press "Verify"
  When I am on the support page
    And I select "2.1" from "Release note"
    And I press "Deploy Verified Code Tickets"
  When I am on the support page
  When I follow "closed" within "#support_tickets"
    And I follow "Support Ticket #4"
    And I should see "fixed in release 2.1"

Scenario: volunteers can re-open a closed code ticket
  When I am logged in as "blair"
    And I follow "Support Board"
    And I follow "closed" within "#code_tickets"
    And I follow "Code Ticket #6"
  When I fill in "reason" with "user says this hasn't fixed their problem"
    And I press "Reopen"
  Then I should see "[open]"
  When I follow "Support Board"
    And I follow "closed" within "#code_tickets"
  Then I should not see "Code Ticket #6"

### comments, votes and watching closed tickets

Scenario: guests can view closed code tickets
  When I am on the page for code ticket 6
  Then I should see "deployed in 1.0"

Scenario: users can view closed code tickets
  When I am logged in as "dean"
    And I am on the page for code ticket 6
  Then I should see "deployed in 1.0"

