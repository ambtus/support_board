Feature: support tickets

### support ticket index

Scenario: can find support tickets a user has commented
  When I am on the home page
    And I follow "Support Board"
    And I follow "Support Tickets"
  Then I should see "Support Ticket #3"
    And I should see "Support Ticket #8"
  When I fill in "With comments by" with "dean"
    And I press "Filter"
  Then I should not see "Support Ticket #8"
  When I follow "Support Ticket #3"
  Then I should see "dean wrote: and the holy water"

Scenario: can find all taken support tickets, and then filter by name
  When I am on the home page
    And I follow "Support Board"
    And I follow "Support Tickets"
    And I select "taken" from "Status"
    And I press "Filter"
  Then I should see "Support Ticket #3"
    And I should see "Support Ticket #9"
    But I should not see "Support Ticket #8"
  When I select "sam" from "Owned by"
    And I press "Filter"
  Then I should not see "Support Ticket #9"
    And I follow "Support Ticket #3"
  Then I should see "taken by sam"

Scenario: can find support tickets waiting for a fix, and then filter by the volunteer who created the link
  When I am logged in as "blair"
    And I am on the home page
    And I follow "Support Board"
    And I follow "Support Tickets"
    And I select "waiting" from "Status"
    And I press "Filter"
  Then I should see "Support Ticket #4"
    And I should see "Support Ticket #7"
  When I select "blair" from "Owned by"
    And I press "Filter"
  Then I should not see "Support Ticket #4"
  When I follow "Support Ticket #7"
  Then I should see "waiting for a code fix "
    And I should see "blair (volunteer): unowned -> waiting (5)"

Scenario: can find support tickets answered with a faq, and then filter by the volunteer who created the link
  When I am logged in as "blair"
    And I am on the home page
    And I follow "Support Board"
    And I follow "Support Tickets"
    And I select "closed" from "Status"
    And I press "Filter"
  Then I should see "Support Ticket #5"
    And I should see "Support Ticket #6"
  When I select "rodney" from "Owned by"
    And I press "Filter"
  Then I should not see "Support Ticket #6"
  When I follow "Support Ticket #5"
  Then I should see "[answered by FAQ how to recover your password]"
    And I should see "rodney (volunteer): unowned -> closed (4)"

### create a new ticket

Scenario: guests can't create a support ticket without a valid email address. (we need it for spam catching, plus it would make the ticket too hard for them to access later)
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I press "Create Support ticket"
  Then I should see "Email does not seem to be a valid address."
    And I should see "Summary can't be blank"
  When I fill in "Summary" with "Archive is very slow"
    And I press "Create Support ticket"
  Then I should see "Email does not seem to be a valid address."
  When I fill in "Email" with "bite me"
    And I press "Create Support ticket"
  Then I should see "Email does not seem to be a valid address."

Scenario: guests can create a support ticket with a valid email address which is not visible even to them or admins
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  Then I should not see "Display my user name"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Archive is very slow"
  But I should not see "guest@ao3.org"
    And I should not see "my user name"
  When I am logged in as "sidra"
    And I am on the page for support ticket 1
  Then I should not see "guest@ao3.org"

Scenario: guests can create a support ticket with initial details. the byline for guests is always generic
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
    And I fill in "content" with "For example, it took a minute for this page to render"
  When I press "Create Support ticket"
    And I should see "ticket owner wrote: For example"
  When I am logged in as "sidra"
    And I am on the page for the last support ticket
    Then I should see "ticket owner wrote: For example"

Scenario: guests can continue to make other changes (persistent authorization)
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
    And I fill in "content" with "For example, it took a minute for this page to render"
    And I press "Add details"
  Then I should see "ticket owner wrote: For example"
  When I fill in "content" with "Never mind, I just found out my whole network is slow"
    And I press "Add details"
  Then I should see "ticket owner wrote: Never mind"

Scenario: guests still have access later in the same session
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Where's the salt?"
    And I press "Create Support ticket"
  When I am on the homepage
  And I follow "Support Board"
  And I follow "Frequently Asked Questions"
    And I follow "where to find salt"
  When I go to the page for the last support ticket
  When I fill in "content" with "Never mind, I just read the FAQ"
    And I press "Add details"
  Then I should see "ticket owner wrote: Never mind"

Scenario: guests can create private support tickets
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Confidential query"
    And I check "Private"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Private"
  When I am logged in as "jim"
    And I follow "Support Board"
    And I follow "Support Tickets"
  Then I should not see "Confidential query"
  When I am logged in as "blair"
    And I follow "Support Board"
    And I follow "Support Tickets"
  Then I should see "Confidential query"

Scenario: guests can create support tickets with no initial notifications
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  And I check "Don't send me email notifications about this ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Please stop sending me notifications"
  When I press "Create Support ticket"
  Then 0 emails should be delivered to "guest@ao3.org"

Scenario: user defaults for opening a new ticket
  Given I am logged in as "dean"
  When I follow "Open a New Support Ticket"
  When I press "Create Support ticket"
  Then I should not see "Email does not seem to be a valid address."
    But I should see "Summary can't be blank"
  When I fill in "Summary" with "Archive is very slow"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Archive is very slow"
    And I should not see "(dean"
  And 1 email should be delivered to "dean@ao3.org"

Scenario: users can create private support tickets
  Given I am logged in as "dean"
  When I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Why are there no results when I search for wattersports?"
    And I check "Private. (Ticket will only be visible to owner and official Support volunteers. This cannot be undone.)"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Why are there no results when I search for wattersports?"
    And I should see "Private"
    And 1 email should be delivered to "dean@ao3.org"
  When I am logged in as "sam"
    And I am on the support page
  When I follow "Support Tickets"
    Then I should see "Why are there no results"
  When I am logged out
    And I am on the support page
  When I am on the page for the last support ticket
  Then I should see "Sorry, you don't have permission"
  When I am logged in as "jim"
    And I am on the support page
  When I follow "Support Tickets"
    Then I should not see "Why are there no results"
  When I am on the page for the last support ticket
  Then I should see "Sorry, you don't have permission"

Scenario: users can choose to have their name displayed during creation, when they comment their login will be shown
  Given I am logged in as "dean"
  When I follow "Open a New Support Ticket"
  When I fill in "Summary" with "Archive is very slow"
    And I fill in "content" with "For example"
    And I uncheck "Anonymous"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Archive is very slow"
    And I should see "dean wrote: For example"
    And I should see "(dean"

### in progress support tickets

Scenario: guests can view in progress code tickets
  When I am on the page for code ticket 2
  Then I should see "taken"

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

Scenario: volunteers can (un)link a support ticket to an existing draft code ticket
  When I am logged in as "blair"
  When I am on the page for code ticket 1
  Then I should see "(1 votes)"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I follow "Support Ticket #1"
    And I select "fix the roof" from "code_ticket_id"
    And I press "Needs this fix"
  Then I should see "[waiting for a code fix fix the roof]"
  Then 1 emails should be delivered to "guest@ao3.org"
  When I am on the page for code ticket 1
  Then I should see "(3 votes)"
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
  Then I should see "(1 votes)"
    And I should not see "Support Ticket #1"
  When I am on the page for support ticket 1
    Then I should see "open"

Scenario: volunteers can open a new code ticket and link to it in one step (with the summary pre-filled in but editable)
  When I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Create new code ticket"
  Then 1 emails should be delivered to "guest@ao3.org"
  When I fill in "Summary" with "something major is broken"
    And I press "Update Code ticket"
  Then I should see "something major is broken"
    And I should see "(3 votes)"
  When I follow "1"
  Then I should see "waiting for a code fix something major is broken"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I select "waiting" from "Status"
    And I press "Filter"
  Then I should see "Support Ticket #1"


Scenario: support board volunteers can untake tickets.
  Given I am logged in as "sam"
    And I am on the page for support ticket 3
  Then I should see "taken by sam"
  When I fill in "Reason" with "the world can save itself"
    When I press "Reopen"
  Then I should see "open"

Scenario: volunteers can steel a support ticket
  When I am logged in as "blair"
    And I am on the support page
    And I follow "taken"
    And I follow "Support Ticket #3"
  Then I should see "taken by sam"
  When I press "Steal"
    Then I should see "taken by blair"
  And 1 email should be delivered to "sam@ao3.org"
    And the email should contain "has been stolen by"
    And the email should contain "blair"

Scenario: support board volunteers can comment on owned tickets.
  When I am logged in as "blair"
    And I am on the support page
    And I follow "taken"
    And I follow "Support Ticket #3"
    When I fill in "content" with "do you need help?"
      And I press "Add details"
    Then I should see "blair (volunteer) wrote: do you need help?"

Scenario: by default, when a volunteer comments, their comments are flagged as by support
  Given I am logged in as "blair"
    And I am on the page for support ticket 7
    And I fill in "content" with "some very interesting things"
    And I press "Add details"
  Then I should see "blair (volunteer) wrote"

Scenario: when a volunteer comments on an open ticket, they can chose to do so as a regular user
  Given I am logged in as "blair"
    And I am on the page for support ticket 1
    And I fill in "content" with "some very interesting things"
    And I choose "unofficial"
    And I press "Add details"
  Then I should see "blair wrote"
    And I should not see "blair (volunteer) wrote"

### resolving support tickets

Scenario: guests can (un)resolve their own support tickets using their own answers
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
    And I fill in "content" with "Never mind"
    And I press "Add details"
  When I select "ticket owner wrote" from "Support Detail"
    And I press "This answer resolves my issue"
  Then I should see "closed by owner"
    And I should see "ticket owner wrote (accepted): Never mind"
  When I fill in "Reason" with "no it didn't"
    And I press "Reopen"
  Then I should see "open"
    And I should see "ticket owner wrote: Never mind"

Scenario: users can comment on unowned tickets and those comments can be chosen as resolutions
  Given I am logged in as "dean"
  When I am on the page for support ticket 8
    And I fill in "content" with "where do you think?"
    And I press "Add details"
  Then I should see "dean wrote: where do you think?"
  When I am logged in as "sam"
  When I am on the page for support ticket 8
    When I select "dean wrote" from "Support Detail"
    And I press "This answer resolves my issue"
  Then I should see "closed by owner"
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
  Then I should see "closed by owner"
    And I should see "jim wrote (accepted): foo bar"
  When I fill in "Reason" with "no it didn't"
    And I press "Reopen"
  Then I should see "open"
    And I should see "jim wrote: foo bar"

Scenario: guests can (un)resolve their own support tickets using a support volunteer answer
  When "blair" comments on support ticket 1
  Then 1 email should be delivered to "guest@ao3.org"
  When I click the first link in the email
  When I select "blair (volunteer) wrote" from "Support Detail"
    And I press "This answer resolves my issue"
  Then I should see "closed by owner"
    And I should see "blair (volunteer) wrote (accepted): foo bar"
  When I fill in "Reason" with "no it didn't"
    And I press "Reopen"
  Then I should see "open"
    And I should see "blair (volunteer) wrote: foo bar"

Scenario: users can (un)resolve their support tickets
  Given I am logged in as "dean"
  And I am on the page for support ticket 3
  And I select "dean wrote" from "Support Detail"
    And I press "This answer resolves my issue"
  Then I should see "closed by owner"
    And I should see "dean wrote (accepted): and the holy water"
  When I fill in "Reason" with "oops. clicked wrong button"
    And I press "Reopen"
  Then I should see "open"
    And I should see "dean wrote: and the holy water"

Scenario: admin's can mark open tickets admin resolved
  When I am logged in as "sidra"
    And I am on the support page
    And I follow "Support Tickets"
    And I follow "Support Ticket #1"
    And I fill in "resolution" with "no longer an issue"
  When I press "Resolve"
  Then I should see "closed by sidra"

Scenario: admin's can mark an admin ticket admin resolved
  When I am logged in as "sam"
    And I go to the page for support ticket 1
    And I press "Needs admin attention"
  When I am logged in as "sidra"
    And I am on the support page
    And I follow "waiting on admin"
    And I follow "Support Ticket #1"
    And I fill in "resolution" with "resent activation code"
  When I press "Resolve"
  Then I should see "closed by sidra"
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
  Then I should see "open"
  When I am on the support page
    And I follow "waiting on admin"
  Then I should not see "some problem"
  When I am on the support page
    And I follow "Support Tickets"
  Then I should see "some problem"

Scenario: volunteers can (un)post a support ticket as a Comment
  When I am logged in as "blair"
  When I follow "Support Board"
  Then I should see "Comments (6)"
    And I should see "Support Tickets (10)"
  When I follow "Support Tickets"
    And I follow "Support Ticket #1"
    And I press "Post as comment"
  When I follow "Support Board"
  Then I should see "Comments (7)"
    And I should see "Support Tickets (9)"
  When I follow "Support Tickets"
  Then I should not see "some problem"
  When I follow "Support Board"
    And I follow "Comments"
    And I follow "#1 (a guest)"
  Then I should see "posted by blair"
  When I fill in "Reason" with "oops"
    And I press "Reopen"
  When I follow "Support Board"
  Then I should see "Comments (6)"
    And I should see "Support Tickets (10)"

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
    And I select "what's a sentinel?" from "faq_id"
    And I press "Answered by this FAQ"
  Then 1 emails should be delivered to "guest@ao3.org"
    And I should see "answered by FAQ what's a sentinel?"
  When I follow "Support Board"
    And I follow "closed" within "#support_tickets"
    And I follow "Support Ticket #1"
  When I fill in "Reason" with "incorrect FAQ"
    And I press "Reopen"
    Then I should see "open"

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
    And I select "where to find salt" from "faq_id"
    And I press "Answered by this FAQ"
  Then 1 emails should be delivered to "guest@ao3.org"
    And I should see "answered by FAQ where to find salt"
  When I follow "Support Board"
    And I follow "closed" within "#support_tickets"
    And I follow "Support Ticket #1"
  When I fill in "Reason" with "incorrect FAQ"
    And I press "Reopen"
    Then I should see "open"

Scenario: volunteers can't link a support ticket to a deployed code ticket
  When I am logged in as "blair"
  When I am on the page for support ticket 1
  Then I should not see "patch the roof"


# TODO
Scenario: Split a support ticket if it has two or more resolutions

# TODO
Scenario: support tickets can be internationalized
Scenario: support tickets can be filtered by language

