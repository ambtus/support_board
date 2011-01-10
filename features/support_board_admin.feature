Feature: the support board as seen by logged in support admins

Scenario: support admins can post drafts which will show up on the FAQ page
  Given a faq exists with position: 1, title: "some question"
  When I am logged in as support admin "incharge"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should not see "some question"
  When I follow "Support Board"
    And I follow "FAQs waiting for comments"
    And I follow "some question"
    And I press "Post"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should see "1: some question"

Scenario: support admins can unpost drafts which will be removed from the FAQ page
  Given a posted faq exists with position: 1, title: "some question"
  When I am logged in as support admin "incharge"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should see "1: some question"
    And I am on the first faq page
    And I fill in "Reason" with "needs more work"
  And I press "Reopen for comments"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should not see "1: some question"
  When I follow "Support Board"
    And I follow "FAQs waiting for comments"
  Then I should see "1: some question"

Scenario: when a draft FAQ is marked posted, the comments are no longer visible.
  Given a faq exists with position: 1
  When I am logged in as "helpful"
    And I am on the first faq page
    And I fill in "Details" with "please include"
    And I press "Add details"
  Then I should see "helpful wrote: please include"
  When I am logged in as volunteer "oracle"
    And I am on the first faq page
    And I fill in "Details" with "don't forget"
    And I press "Add details"
  Then I should see "oracle (volunteer) wrote: don't forget"
  When I am logged in as support admin "incharge"
    And I am on the first faq page
    And I press "Post"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should see "1: faq 1"
    But I should not see "helpful wrote: please include"
    And I should not see "oracle (volunteer) wrote: don't forget"

Scenario: admin's can mark an admin ticket admin resolved
  Given a support ticket exists with summary: "please resend activation code", id: 1
  When I am logged in as volunteer "oracle"
    And I go to the first support ticket page
    And I press "Needs admin attention"
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I follow "Support tickets requiring Admin attention"
    And I follow "Support Ticket #1"
    And I fill in "Resolution" with "resent activation code"
  When I press "Resolve"
  Then I should see "Status: closed by incharge"
  When I follow "Support Board"
    And I follow "Support tickets requiring Admin attention"
  Then I should not see "Support Ticket #1"
  When I am logged in as support admin "newchair"
    And I follow "Support Board"
    And I follow "Closed Support Tickets"
    And I follow "Support Ticket #1"
    And I fill in "Reason" with "still didn't work, may be a bug"
  When I press "Reopen"
  Then I should see "Status: open"
  When I follow "Support Board"
    And I follow "Support tickets requiring Admin attention"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should see "Support Ticket #1"

Scenario: admin's can mark open tickets admin resolved
  Given a support ticket exists with summary: "something random", id: 1
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I fill in "Resolution" with "no longer an issue"
  When I press "Resolve"
  Then I should see "Status: closed by incharge"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Support tickets requiring Admin attention"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Closed Support Tickets"
  Then I should see "Support Ticket #1"

Scenario: entering a stage version number will stage all the relevant committed tickets
  Given a volunteer exists with login: "rodney"
    And a code ticket exists with id: 1
    And a code ticket exists with id: 2
    And a code ticket exists with id: 3
    And "rodney" commits code ticket 1 in "2001"
    And "rodney" commits code ticket 2 in "2000"
    And "rodney" commits code ticket 3 in "1000"
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I fill in "Stage revision" with "2000"
    And I press "Stage Committed Code Tickets"
    And I follow "Staged Code Tickets"
  Then I should see "Code Ticket #2"
    And I should see "Code Ticket #3"
    But I should not see "Code Ticket #1"
  When I follow "Support Board"
    And I follow "Committed Code Tickets"
  Then I should see "Code Ticket #1"
    But I should not see "Code Ticket #2"
    And I should not see "Code Ticket #3"

Scenario: updating the version number will deploy all the verified code tickets and attach a release note
  Given a support admin exists with login: "incharge"
    And the current SupportBoard version is "2000"
    And a code ticket exists with id: 1
    And a code ticket exists with id: 2
    And a code ticket exists with id: 3
    And a code ticket exists with id: 4
    And a release note exists with release: "8.5.7"
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I follow "Release Notes"
    Then I should not see "8.5.7"
  When I follow "Support Board"
    And I follow "Draft Release Notes"
    Then I should see "8.5.7"
  When "incharge" verifies code ticket 1 in "2000"
    And "incharge" verifies code ticket 2 in "2001"
    And "incharge" verifies code ticket 3 in "1000"
    And "incharge" stages code ticket 4 in "1050"
  When I follow "Support Board"
    And I select "8.5.7" from "Release note"
    And I press "Deploy Verified Code Tickets"
  Then I should see "1"
    And I should see "3"
    But I should not see "2"
    And I should not see "4"
  When I follow "Support Board"
    And I follow "Staged Code Tickets"
  Then I should see "Code Ticket #4"
    But I should not see "Code Ticket #1"
    And I should not see "Code Ticket #2"
    And I should not see "Code Ticket #3"
  When I follow "Support Board"
    And I follow "Verified Code Tickets"
  Then I should see "Code Ticket #2"
    But I should not see "Code Ticket #1"
    And I should not see "Code Ticket #3"
    And I should not see "Code Ticket #4"
  When I follow "Support Board"
    And I follow "Closed Code Tickets"
  Then I should see "Code Ticket #1"
    And I should see "Code Ticket #3"
    But I should not see "Code Ticket #2"
    And I should not see "Code Ticket #4"
  When I follow "Support Board"
    And I follow "Release Notes"
    And I follow "8.5.7"

Scenario: updating the version number will close all the waiting support tickets
  Given a support admin exists with login: "incharge"
    And a volunteer exists with login: "oracle"
  Given a code ticket exists with id: 1
    And a code ticket exists with id: 2
    And a code ticket exists with id: 3
    And a release note exists with release: "8.5.7"
  Given "incharge" verifies code ticket 1 in "1999"
    And "incharge" verifies code ticket 2 in "2001"
    And "incharge" commits code ticket 3 in "1999"
    And the current SupportBoard version is "2000"
  Given a support ticket exists with id: 1
    And a support ticket exists with id: 2
    And a support ticket exists with id: 3
    And "oracle" links support ticket 1 to code ticket 1
    And "oracle" links support ticket 2 to code ticket 2
    And "oracle" links support ticket 3 to code ticket 3
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I select "8.5.7" from "Release note"
    And I press "Deploy Verified Code Tickets"
  When I follow "Support Board"
    And I follow "Closed Support Tickets"
  Then I should see "Support Ticket #1"
    But I should not see "Support Ticket #2"
    And I should not see "Support Ticket #3"

Scenario: support admins (only - privacy issues) can see the authenticity_token, browser agent and originating IP
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Archive is very slow"
  But I should not see "guest@ao3.org"
    And I should not see "authenticity_token"
    And I should not see "agent"
    And I should not see "Remote IP"
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #"
  Then I should see "Archive is very slow"
    And I should see "authenticity_token:"
    And I should see "user agent:"
    And I should see "remote IP: 127.0.0.1"

# TODO
Scenario: support admins can edit release notes which have been posted
