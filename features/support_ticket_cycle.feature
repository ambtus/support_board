Feature: support tickets life cycle

Scenario: volunteers can not mark a user opened support ticket spam
  When I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I follow "Support Ticket #8"
  # FIXME this doesn't fail when the code is wrong: can't "see" submit labels
  Then I should not see "Spam"

Scenario: guests can (un)resolve their own support tickets using their own answers
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
    And I fill in "Details" with "Never mind"
    And I press "Add details"
  When I select "ticket owner wrote" from "Support Detail"
    And I press "This answer resolves my issue"
  Then I should see "Status: closed by owner"
    And I should see "ticket owner wrote (accepted): Never mind"
  When I fill in "Reason" with "no it didn't"
    And I press "Reopen"
  Then I should see "Status: open"
    And I should see "ticket owner wrote: Never mind"

Scenario: users can comment on unowned tickets and those comments can be chosen as resolutions
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
    And I follow "Support Tickets"
  Then I should not see "Support Ticket #8"

# TODO
Scenario: a users's support_identity can be banned by a support admin after which they can no longer comment

Scenario: guests can (un)resolve their own support tickets using a user answer
  When "jim" comments on support ticket 1
  Then 1 email should be delivered to "guest@ao3.org"
  When I click the first link in the email
  When I select "jim wrote" from "Support Detail"
    And I press "This answer resolves my issue"
  Then I should see "Status: closed by owner"
    And I should see "jim wrote (accepted): foo bar"
  When I fill in "Reason" with "no it didn't"
    And I press "Reopen"
  Then I should see "Status: open"
    And I should see "jim wrote: foo bar"

Scenario: guests can (un)resolve their own support tickets using a support volunteer answer
  When "blair" comments on support ticket 1
  Then 1 email should be delivered to "guest@ao3.org"
  When I click the first link in the email
  When I select "blair (volunteer) wrote" from "Support Detail"
    And I press "This answer resolves my issue"
  Then I should see "Status: closed by owner"
    And I should see "blair (volunteer) wrote (accepted): foo bar"
  When I fill in "Reason" with "no it didn't"
    And I press "Reopen"
  Then I should see "Status: open"
    And I should see "blair (volunteer) wrote: foo bar"

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

Scenario: users cannot comment on owned tickets.
  Given I am logged in as "jim"
  When I am on the page for support ticket 3
  Then I should see "Status: taken by sam"
  And I should not see "Details"

Scenario: admin's can mark open tickets admin resolved
  When I am logged in as "sidra"
    And I am on the support page
    And I follow "Support Tickets"
    And I follow "Support Ticket #1"
    And I fill in "Resolution" with "no longer an issue"
  When I press "Resolve"
  Then I should see "Status: closed by sidra"

Scenario: admin's can mark an admin ticket admin resolved
  When I am logged in as "sam"
    And I go to the page for support ticket 1
    And I press "Needs admin attention"
  When I am logged in as "sidra"
    And I am on the support page
    And I follow "waiting on admin"
    And I follow "Support Ticket #1"
    And I fill in "Resolution" with "resent activation code"
  When I press "Resolve"
  Then I should see "Status: closed by sidra"
  When I am on the support page
    And I follow "waiting on admin"
  Then I should not see "Support Ticket #1 some problem"

  # volunteers can reopen any ticket, even those closed by an admin
  When I am logged in as "sam"
    And I am on the support page
    And I follow "closed" within "#support_tickets"
    And I follow "Support Ticket #1"
    And I fill in "Reason" with "still didn't work, may be a bug"
  When I press "Reopen"
  Then I should see "Status: open"
  When I am on the support page
    And I follow "waiting on admin"
  Then I should not see "Support Ticket #1 some problem"
  When I am on the support page
    And I follow "Support Tickets"
  Then I should see "Support Ticket #1 [unowned] some problem"

Scenario: volunteers can mark a support ticket for an Admin to resolve
  When I am logged in as "blair"
  When I follow "Support Board"
  Then I should see "waiting on admin (2)"
  When I follow "Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Needs admin attention"
  When I follow "Support Board"
  Then I should see "waiting on admin (3)"
    And I follow "waiting on admin"
    And I follow "Support Ticket #1"
  When I fill in "Reason" with "oops"
    And I press "Reopen"
  When I follow "Support Board"
  Then I should see "waiting on admin (2)"

Scenario: volunteers can (un)post a support ticket as a Comment
  When I am logged in as "blair"
  When I follow "Support Board"
  Then I should see "Comments (6)"
    And I should see "Support Tickets (11)"
  When I follow "Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Post as comment"
  When I follow "Support Board"
  Then I should see "Comments (7)"
    And I should see "Support Tickets (10)"
  When I follow "Support Tickets"
  Then I should not see "some problem"
  When I follow "Support Board"
    And I follow "Comments"
    And I follow "#1"
  Then I should see "Status: posted by blair"
  When I fill in "Reason" with "oops"
    And I press "Reopen"
  When I follow "Support Board"
  Then I should see "Comments (6)"
    And I should see "Support Tickets (11)"

Scenario: volunteers can (un)link a support ticket to an existing code ticket
  When I am logged in as "blair"
  When I am on the page for code ticket 1
  Then I should see "Votes: 1"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I follow "Support Ticket #1"
    And I select "fix the roof"
    And I press "Needs this fix"
  Then I should see "[waiting for a code fix fix the roof]"
  Then 1 emails should be delivered to "guest@ao3.org"
  When I am on the page for code ticket 1
  Then I should see "Votes: 3"
    And I should see "Related Support tickets"
  When I follow "1"
  Then I should see "[waiting for a code fix fix the roof]"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I select "waiting" from "Status"
    And I press "Filter"
    And I follow "Support Ticket #1"
  When I fill in "Reason" with "wrong code ticket"
    And I press "Reopen"
  When I am on the page for code ticket 1
  Then I should see "Votes: 1"
    And I should not see "Support Ticket #1"
  When I am on the page for support ticket 1
    Then I should see "Status: open"

Scenario: volunteers can open a new code ticket and link to it in one step (with the summary pre-filled in but editable)
  When I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Create new code ticket"
  Then 1 emails should be delivered to "guest@ao3.org"
  When I fill in "Summary" with "something major is broken"
    And I press "Update Code ticket"
  Then I should see "Summary: something major is broken"
    And I should see "Votes: 3"
  When I follow "1"
  Then I should see "Status: waiting for a code fix Code Ticket #"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I select "waiting" from "Status"
    And I press "Filter"
  Then I should see "Support Ticket #1"

Scenario: volunteers can link a support ticket to an existing draft FAQ
  When I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
    Then I should not see "what's a sentinel?"
  When I follow "Support Board"
    And I follow "drafts" within "#faqs"
    Then I should see "what's a sentinel?"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I follow "Support Ticket #1"
    And I select "what's a sentinel?" from "FAQ"
    And I press "Answered by this FAQ"
  Then 1 emails should be delivered to "guest@ao3.org"
    And I should see "Status: closed by blair what's a sentinel?"
  When I follow "Support Board"
    And I follow "closed" within "#support_tickets"
    And I follow "Support Ticket #1"
  When I fill in "Reason" with "incorrect FAQ"
    And I press "Reopen"
    Then I should see "Status: open"

Scenario: volunteers can link a support ticket to an existing posted FAQ
  When I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
    Then I should see "where to find salt"
  When I follow "Support Board"
    And I follow "drafts" within "#faqs"
    Then I should not see "where to find salt"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I follow "Support Ticket #1"
    And I select "where to find salt" from "FAQ"
    And I press "Answered by this FAQ"
  Then 1 emails should be delivered to "guest@ao3.org"
    And I should see "Status: closed by blair where to find salt"
  When I follow "Support Board"
    And I follow "closed" within "#support_tickets"
    And I follow "Support Ticket #1"
  When I fill in "Reason" with "incorrect FAQ"
    And I press "Reopen"
    Then I should see "Status: open"

Scenario: volunteers can create a new (draft) FAQ and link to it in one step
  When I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Create new FAQ"
  Then 1 emails should be delivered to "guest@ao3.org"
  When I fill in "Summary" with "New question"
    And I press "Update Faq"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
    Then I should not see "New question"
  When I follow "Support Board"
    And I follow "drafts" within "#faqs"
    Then I should see "New question"
  When I follow "Support Board"
    And I follow "closed" within "#support_tickets"
    And I follow "Support Ticket #1"
  Then I should see "Status: closed by blair New question"

Scenario: support board volunteers can untake tickets.
  Given I am logged in as "sam"
    And I am on the page for support ticket 3
  Then I should see "Status: taken by sam"
  When I fill in "Reason" with "the world can save itself"
    When I press "Reopen"
  Then I should see "Status: open"

Scenario: volunteers can steel a support ticket
  When I am logged in as "blair"
    And I am on the support page
    And I follow "taken"
    And I follow "Support Ticket #3"
  Then I should see "Status: taken by sam"
  When I press "Steal"
    Then I should see "Status: taken by blair"
  And 1 email should be delivered to "sam@ao3.org"
    And the email should contain "has been stolen by"
    And the email should contain "blair"

Scenario: support board volunteers can comment on owned tickets.
  When I am logged in as "blair"
    And I am on the support page
    And I follow "taken"
    And I follow "Support Ticket #3"
    When I fill in "Details" with "do you need help?"
      And I press "Add details"
    Then I should see "blair (volunteer) wrote: do you need help?"

Scenario: by default, when a volunteer comments, their comments are flagged as by support
  Given I am logged in as "blair"
    And I am on the page for support ticket 7
    And I fill in "Details" with "some very interesting things"
    And I press "Add details"
  Then I should see "blair (volunteer) wrote"

Scenario: when a volunteer comments on an open ticket, they can chose to do so as a regular user
  Given I am logged in as "blair"
    And I am on the page for support ticket 1
    And I fill in "Details" with "some very interesting things"
    And I uncheck "Official response?"
    And I press "Add details"
  Then I should see "blair wrote"
    And I should not see "blair (volunteer) wrote"

