Feature: code tickets life cycle

Scenario: creating a code ticket from a support ticket should enter referring url in url
  When I am logged in as "sam"
    And I am on the page for support ticket 8
  Then I should not see "referring url: /users/dean"
    And I should not see "Take"
  And I follow "view ticket as support volunteer"
  Then I should see "referring url: /users/dean"
  When I press "Create new code ticket"
    And I am on the page for the last code ticket
  Then I should see "url: /users/dean"

Scenario: creating a code ticket from a support ticket should enter user agent in browser
  When I am logged in as "blair"
    And I am on the page for support ticket 1
  Then I should see "user agent: Mozilla/5.0"
  When I press "Create new code ticket"
    And I am on the page for the last code ticket
  Then I should see "browser: Mozilla/5.0"

Scenario: admin's can transition a code ticket to committed by linking it to a code commit
  When I am logged in as "bofh"
    And I am on the support page
  When I follow "taken" within "#support_tickets"
    And I follow "Support Ticket #3"
    Then I should see "Status: taken by sam"
  When I am on the support page
    And I follow "Unmatched Commits"
  When I follow "1 by sam"
    And I select "save the world" from "Code Ticket"
    And I press "Match"
  Then I should be on the code commits page
    And I should not see "1 by sam"
  When I am on the support page
    And I follow "committed"
    And I follow "Code Ticket #2"
    And I should see "committed by sam"
    And I should see "Commit 1 by sam (Github): no issue number"

Scenario: admin's can stage committed tickets once they are all matched
  When I am logged in as "rodney"
    And I am on the support page
  Then I should see "committed (1)"
    And I follow "committed"
  Then I should see "Code Ticket #5"
  When I am on the support page
    Then I should see "Unmatched Commits (1)"
  When I follow "Unmatched Commits"
    And I follow "1 by sam"
    And I select "save the world" from "Code Ticket"
    And I press "Match"
  When I am on the support page
    And I press "Stage Committed Code Tickets"
  When I am on the support page
  Then I should see "committed (0)"
  When I follow "staged"
    Then I should see "Code Ticket #5"

Scenario: volunteers can verify staged Tickets
  When I am logged in as "sam"
    And I follow "Support Board"
    And I follow "staged"
  Then I should see "Code Ticket #4 (0) build a zpm"
  When I follow "Code Ticket #4"
    And I press "Verify"
  Then I should see "Status: verified by sam"
    When I follow "Support Board"
    And I follow "staged"
  Then I should not see "Code Ticket #4"

Scenario: admins can deploy the code tickets once they have all been verified and there is a draft release note
  When I am logged in as "bofh"
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
    Then I should not see "2.0"
  When I am on the support page
    And I follow "drafts" within "#release_notes"
    Then I should see "2.0"
  When I am on the support page
  Then I should not see "1.0"
  When I select "2.0" from "Release note"
    And I press "Deploy Verified Code Tickets"
  Then I should see "2.0"
  When I am on the support page
  Then I should see "staged (0)"
    And I should see "verified (0)"

Scenario: deploying should close the waiting support tickets
  When I am logged in as "bofh"
    And I am on the support page
  Then I should see "waiting for code changes (3)"
  When I follow "waiting for code changes"
    And I follow "Support Ticket #4"
  Then I should see "repeal DADT"
    And I should see "Status: waiting for a code fix"
  When I am on the support page
  When I follow "staged"
    And I follow "Code Ticket #4"
    And I press "Verify"
  When I am on the support page
    And I select "2.0" from "Release note"
    And I press "Deploy Verified Code Tickets"
  When I am on the support page
  When I follow "closed" within "#support_tickets"
    And I follow "Support Ticket #4"
    And I should see "Status: fixed in 2.0"

Scenario: volunteers can re-open a closed code ticket
  When I am logged in as "blair"
    And I follow "Support Board"
    And I follow "closed" within "#code_tickets"
    And I follow "Code Ticket #6"
  When I fill in "reason" with "user says this hasn't fixed their problem"
    And I press "Reopen"
  Then I should see "Status: open"
  When I follow "Support Board"
    And I follow "closed" within "#code_tickets"
  Then I should not see "Code Ticket #6"

