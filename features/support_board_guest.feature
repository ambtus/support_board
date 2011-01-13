Feature: the support board as seen by guests

Scenario: guests can view public tickets if they have a link but they can't comment on them so they don't see a link from the support board
  When I am on the support page
    Then I should not see "Open Support Tickets"
  When I am on the page for support ticket 1
  Then I should see "some problem"
    But I should not see "Details:"

Scenario: guests can't access private tickets even with a direct link.
  When I am on the page for support ticket 2
  Then I should see "Sorry, you don't have permission"
    And I should not see "a personal problem"

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
  When I am logged in as "bofh"
    And I am on the page for support ticket 1
  Then I should not see "guest@ao3.org"

Scenario: guests can create a support ticket with initial details. the byline for guests is always generic
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
    And I fill in "Details" with "For example, it took a minute for this page to render"
  When I press "Create Support ticket"
    And I should see "ticket owner wrote: For example"
  When I am logged in as "bofh"
    And I am on the page for the last support ticket
    Then I should see "ticket owner wrote: For example"

Scenario: guests should receive email notification on creation
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  Then 1 email should be delivered to "guest@ao3.org"

Scenario: guests email notifications should have a link with authentication code
  When "dean" comments on support ticket 1
  Then 1 email should be delivered to "guest@ao3.org"
  When I click the first link in the email
  Then I should see "Details:"

Scenario: guests can continue to make other changes (persistent authorization)
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
    And I fill in "Details" with "For example, it took a minute for this page to render"
    And I press "Add details"
  Then I should see "ticket owner wrote: For example"
  When I fill in "Details" with "Never mind, I just found out my whole network is slow"
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
  When I fill in "Details" with "Never mind, I just read the FAQ"
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
    And I should see "Access: Private"
  When I am logged in as "jim"
    And I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Confidential query"
  When I am logged in as "blair"
    And I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should see "Confidential query"

Scenario: guests can create support tickets with no initial notifications
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  And I check "Don't send me email notifications about this ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Please stop sending me notifications"
  When I press "Create Support ticket"
  Then 0 emails should be delivered to "guest@ao3.org"

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

Scenario: guests can toggle notifications for individual tickets
  When I am on the home page
    And I follow "Support Board"
    And I fill in "email" with "guest@ao3.org"
    And I press "Send me access links to my support tickets"
  Then 1 email should be delivered to "guest@ao3.org"
    And all emails have been delivered
  When I click the first link in the email
    And I press "Don't watch this ticket"
    And "sam" comments on support ticket 1
  Then 0 emails should be delivered to "guest@ao3.org"

  # turning off notifications for one shouldn't affect the other
  When "sam" comments on support ticket 2
  Then 1 emails should be delivered to "guest@ao3.org"

Scenario: guests can't make their private support tickets public
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
    And I check "Private"
  When I press "Create Support ticket"
  Then I should see "Access: Private"
    But I should not see "Ticket will only be visible"

Scenario: guests can make their public support tickets private, even to people who already commented who should no longer get email
  When "jim" watches support ticket 1
    And "jim" comments on support ticket 1
  Then 1 email should be delivered to "jim@ao3.org"
  Then 1 email should be delivered to "guest@ao3.org"
    And all emails have been delivered
  When I click the first link in the email
    Then I should see "Ticket will only be visible"
  When I press "Make private"
    And I am logged in as "jim"
    And I am on the page for support ticket 1
  Then I should see "Sorry, you don't have permission"
  When "sam" comments on support ticket 1
  Then 1 email should be delivered to "guest@ao3.org"
  And 0 emails should be delivered to "jim@ao3.org"

Scenario: email to others shouldn't include the authorization
  When I am logged in as "jim"
    And I am on the page for support ticket 1
    And I press "Watch this ticket"
  When I am logged out
    And "sam" comments on support ticket 1
  Then 1 email should be delivered to "jim@ao3.org"
  When I click the first link in the email
  Then I should see "sam (volunteer) wrote"
    But I should not see "Ticket will only be visible"

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

Scenario: guests can view open code tickets, but not vote or comment
  When I am on the page for code ticket 1
  Then I should see "Status: open"
  But I should not see "Vote up"
    And I should not see "Details:"

Scenario: guests can view in progress code tickets, but not vote or comment
  When I am on the page for code ticket 2
  Then I should see "Status: taken"
  But I should not see "Vote up"
    And I should not see "Details:"

Scenario: guests can view closed code tickets, but not vote or comment
  When I am on the page for the last code ticket
  Then I should see "Status: deployed in 1.0"
  But I should not see "Vote up"
    And I should not see "Details:"

Scenario: guests reading a draft FAQ can mark it as "this answered my question" (a FAQ vote) but not comment
  When I am on the page for faq 2
  Then I should see "why we don't have enough ZPMs"
  When I press "This FAQ answered my question"
  Then I should see "Votes: 1"
    But I should not see "Details"

Scenario: guests reading a posted FAQ can mark it as "this answered my question" (a FAQ vote) but not comment
  When I am on the page for faq 1
  Then I should see "where to find salt"
  When I press "This FAQ answered my question"
  Then I should see "Votes: 1"
    But I should not see "Details"

Scenario: guests can comment on a draft FAQ when following a link from their own support ticket
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "new question"
    And I press "Create Support ticket"
  When "sam" creates a faq from support ticket 9
    And I reload the page
  Then I should see "Status: closed by sam"
  When I follow "new faq"
    And I fill in "Details" with "this sounds good"
    And I press "Add details"
  Then I should see "support ticket owner wrote: this sounds good"

Scenario: guests can't comment on a posted FAQ when following a link from their own support ticket
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "where's the salt?"
    And I press "Create Support ticket"
  When "sam" links support ticket 9 to faq 1
    And I reload the page
  Then I should see "Status: closed by sam"
  When I follow "where to find salt"
    Then I should not see "Details"

Scenario: an existing faq should get a vote when linked from a guest support ticket
  When I am on the page for faq 2
    Then I should see "Votes: 0"
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When "rodney" links support ticket 1 to faq 2
  When I am on the page for faq 2
    And I should see "Votes: 1"

Scenario: a faq should get a vote when it's created from a guest support ticket
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
    And "rodney" creates a faq from support ticket 1
  When I am on the page for the last faq
  Then I should see "Votes: 1"

Scenario: an existing faq should get a vote removed when unlinked from a guest support ticket
  When I am on the page for faq 2
    Then I should see "Votes: 0"
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When "rodney" links support ticket 9 to faq 2
    And I reload the page
  Then I should see "why we don't have enough ZPMs"
     And I should see "Status: closed by rodney"
  When I fill in "Reason" with "I don't even know what a ZPM is"
    And I press "Reopen"
  Then I should see "Status: open"
    And I should not see "why we don't have enough ZPMs"
  When I am on the page for faq 2
  Then I should see "Votes: 0"

Scenario: a new faq should get a vote removed when unlinked from a guest support ticket
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When "blair" creates a faq from support ticket 9
    And I reload the page
  When I fill in "Reason" with "FAQ not helpful"
    And I press "Reopen"
  Then I should see "Status: open"
  When I am on the page for the last faq
  Then I should see "Votes: 0"

Scenario: FAQs can be sorted by votes
  Given the following faq votes exist
    | faq_id | vote  |
    | 1      | 3     |
    | 2      | 1     |
    | 3      | 7     |
    | 4      | 9     |
    | 5      | 3     |
  When I am on the home page
    And I follow "Support Board"
    And I follow "All FAQs"
  Then I should see "1: where to find salt (3)"
    And I should see "2: why we don't have enough ZPMs (1)"
    And I should see "3: what's DADA? (7)"
    And I should see "4: how to recover your password (10)"
    And I should see "5: what's a sentinel? (4)"
  When I follow "Sort by vote count"
  Then I should see "4: where to find salt (3)"
    And I should see "5: why we don't have enough ZPMs (1)"
    And I should see "2: what's DADA? (7)"
    And I should see "1: how to recover your password (10)"
    And I should see "3: what's a sentinel? (4)"

Scenario: code tickets can be sorted by votes
  Given the following code votes exist
    | code_ticket_id | vote  |
    | 1              | 3     |
    | 2              | 7     |
    | 3              | 18    |
  When I am on the home page
    And I follow "Support Board"
    And I follow "Open Code Tickets (Known Issues)"
  Then I should see "1: Code Ticket #1 (3) fix the roof"
    And I should see "2: Code Ticket #2 (7) save the world "
    And I should see "3: Code Ticket #3 (20) repeal DADA "
    And I should see "4: Code Ticket #4 (0) build a zpm "
    And I should see "5: Code Ticket #5 (2) find a sentinel "
  When I follow "Sort by vote count"
  Then I should see "3: Code Ticket #1 (3) fix the roof"
    And I should see "2: Code Ticket #2 (7) save the world "
    And I should see "1: Code Ticket #3 (20) repeal DADA "
    And I should see "5: Code Ticket #4 (0) build a zpm "
    And I should see "4: Code Ticket #5 (2) find a sentinel "
