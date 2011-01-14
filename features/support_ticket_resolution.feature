Feature: support tickets can be marked as spam, posted as a comment, closed by and admin, have an answer accepted, or be associated with a faq or code ticket

Scenario: volunteers can mark a support ticket spam/ham, which doesn't send notifications
  When I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Mark as spam"
  Then 0 emails should be delivered to "guest@ao3.org"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Spam"
    And I follow "Support Ticket #1"
    And I press "Mark as ham"
  Then I should see "Status: open"
    And 0 emails should be delivered to "guest@ao3.org"
  When I follow "Support Board"
    And I follow "Spam"
  Then I should not see "Support Ticket #1"

Scenario: volunteers can not mark a user opened support ticket spam
  When I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
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
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #3"
  When I am on the page for support ticket 3
  Then I should see "Status: taken by sam"
  And I should not see "Details"

Scenario: admin's can mark open tickets admin resolved
  When I am logged in as "bofh"
    And I am on the support page
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I fill in "Resolution" with "no longer an issue"
  When I press "Resolve"
  Then I should see "Status: closed by bofh"

Scenario: admin's can mark an admin ticket admin resolved
  When I am logged in as "sam"
    And I go to the page for support ticket 1
    And I press "Needs admin attention"
  When I am logged in as "bofh"
    And I am on the support page
    And I follow "Support tickets requiring Admin attention"
    And I follow "Support Ticket #1"
    And I fill in "Resolution" with "resent activation code"
  When I press "Resolve"
  Then I should see "Status: closed by bofh"
  When I am on the support page
    And I follow "Support tickets requiring Admin attention"
  Then I should not see "Support Ticket #1"

  # volunteers can reopen any ticket, even those closed by an admin
  When I am logged in as "sam"
    And I am on the support page
    And I follow "Closed Support Tickets"
    And I follow "Support Ticket #1"
    And I fill in "Reason" with "still didn't work, may be a bug"
  When I press "Reopen"
  Then I should see "Status: open"
  When I am on the support page
    And I follow "Support tickets requiring Admin attention"
  Then I should not see "Support Ticket #1"
  When I am on the support page
    And I follow "Open Support Tickets"
  Then I should see "Support Ticket #1"

Scenario: volunteers can mark a support ticket for an Admin to resolve
  When I am logged in as "blair"
  When I follow "Support Board"
  Then I should see "Support tickets requiring Admin attention (0)"
  When I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Needs admin attention"
  When I follow "Support Board"
  Then I should see "Support tickets requiring Admin attention (1)"
    And I follow "Support tickets requiring Admin attention"
    And I follow "Support Ticket #1"
  When I fill in "Reason" with "oops"
    And I press "Reopen"
  When I follow "Support Board"
  Then I should see "Support tickets requiring Admin attention (0)"

Scenario: volunteers can (un)post a support ticket as a Comment
  When I am logged in as "blair"
  When I follow "Support Board"
  Then I should see "Comments (0)"
    And I should see "Open Support Tickets (2)"
  When I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Post as comment"
  When I follow "Support Board"
  Then I should see "Comments (1)"
    And I should see "Open Support Tickets (1)"
  When I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Comments"
    And I follow "#1"
  Then I should see "Status: posted by blair"
  When I fill in "Reason" with "oops"
    And I press "Reopen"
  When I follow "Support Board"
  Then I should see "Comments (0)"
    And I should see "Open Support Tickets (2)"

Scenario: volunteers can (un)link a support ticket to an existing code ticket
  When I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I select "1" from "Code Ticket"
    And I press "Needs this fix"
  Then 1 emails should be delivered to "guest@ao3.org"
  When I am on the page for code ticket 1
  Then I should see "Votes: 2"
    And I should see "Related Support tickets"
  When I follow "1"
  Then I should see "Status: waiting for a code fix Code Ticket #1"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Support Tickets waiting for Code changes"
    And I follow "Support Ticket #1"
  When I fill in "Reason" with "wrong code ticket"
    And I press "Reopen"
  When I am on the page for code ticket 1
  Then I should see "Votes: 0"
    And I should not see "Support Ticket #1"
  When I am on the page for support ticket 1
    Then I should see "Status: open"

Scenario: volunteers can open a new code ticket and link to it in one step (with the summary pre-filled in but editable)
  When I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Create new code ticket"
  Then 1 emails should be delivered to "guest@ao3.org"
  When I fill in "Summary" with "something major is broken"
    And I fill in "Description" with "blah blah and some more blah"
    And I press "Update Code ticket"
  Then I should see "Summary: something major is broken"
    And I should see "Description: blah blah and some more blah"
    And I should see "Votes: 3"
  When I follow "1"
  Then I should see "Status: waiting for a code fix Code Ticket #"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Support Tickets waiting for Code changes"
  Then I should see "Support Ticket #1"

Scenario: volunteers can link a support ticket to an existing draft FAQ
  When I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
    Then I should not see "what's a sentinel?"
  When I follow "Support Board"
    And I follow "FAQs waiting for comments"
    Then I should see "what's a sentinel?"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I select "what's a sentinel?" from "FAQ"
    And I press "Answered by this FAQ"
  Then 1 emails should be delivered to "guest@ao3.org"
    And I should see "Status: closed by blair what's a sentinel?"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Closed Support Tickets"
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
    And I follow "FAQs waiting for comments"
    Then I should not see "where to find salt"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I select "where to find salt" from "FAQ"
    And I press "Answered by this FAQ"
  Then 1 emails should be delivered to "guest@ao3.org"
    And I should see "Status: closed by blair where to find salt"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Closed Support Tickets"
    And I follow "Support Ticket #1"
  When I fill in "Reason" with "incorrect FAQ"
    And I press "Reopen"
    Then I should see "Status: open"

Scenario: volunteers can create a new (draft) FAQ and link to it in one step
  When I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Create new FAQ"
  Then 1 emails should be delivered to "guest@ao3.org"
  When I fill in "Title" with "New question"
    And I press "Update Faq"
  When I follow "Support Board"
    And I follow "Frequently Asked Questions"
    Then I should not see "New question"
  When I follow "Support Board"
    And I follow "FAQs waiting for comments"
    Then I should see "New question"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #1"
  When I follow "Support Board"
    And I follow "Closed Support Tickets"
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
    And I am on sam's user page
    And I follow "Taken Support Tickets"
    And I follow "Support Ticket #3"
  Then I should see "Status: taken by sam"
  When I press "Steal"
    Then I should see "Status: taken by blair"
  And 1 email should be delivered to "sam@ao3.org"
    And the email should contain "has been stolen by"
    And the email should contain "blair"

Scenario: support board volunteers can comment on owned tickets.
  When I am logged in as "blair"
    And I am on sam's user page
    And I follow "Taken Support Tickets"
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

