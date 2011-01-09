Feature: the support board as seen by guests

Scenario: guests can view public tickets but not comment on them.
  Given a support ticket exists with summary: "publicly visible"
  When I go to the first support ticket page
  Then I should see "publicly visible"
    But I should not see "Details:"

Scenario: guests can't access private tickets even with a direct link.
  Given a support ticket exists with private: true
  When I go to the first support ticket page
  Then I should see "Sorry, you don't have permission"

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

Scenario: guests can create a support ticket with a valid email address which is not visible even by choice
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Archive is very slow"
  But I should not see "guest@ao3.org"
    And I should not see "Display my user name"

Scenario: guests can create a support ticket with initial details. the byline for guests is always generic
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
    And I fill in "Details" with "For example, it took a minute for this page to render"
  When I press "Create Support ticket"
    And I should see "ticket owner wrote: For example"

Scenario: guests should receive email notification
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  Then 1 email should be delivered to "guest@ao3.org"

Scenario: guests email notifications should have a link with authentication code
  Given a support ticket exists
    And all emails have been delivered
  When a volunteer comments on support ticket 1
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
    And I fill in "Summary" with "Archive is very slow"
    And I press "Create Support ticket"
  When I am on the homepage
  And I follow "Support Board"
  And I follow "Comments"
  When I go to the page for the first support ticket
    Then I should see "Details:"

Scenario: guests can create private support tickets
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Confidential query"
    And I check "Private"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Access: Private"
  When I am logged in as "helpful"
    And I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #"
  When I am logged in as volunteer "oracle"
    And I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should see "Support Ticket #"

Scenario: guests can create support tickets with no initial notifications
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  And I check "Don't send me email notifications about this ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Please stop sending me notifications"
  When I press "Create Support ticket"
  Then 0 emails should be delivered to "guest@ao3.org"

Scenario: guests can enter an email address to have authorized links re-sent
  Given a support ticket exists with id: 1, summary: "first"
    And a support ticket exists with id: 2, summary: "second"
    And all emails have been delivered
  When I am on the home page
    And I follow "Support Board"
    And I fill in "email" with "guest@ao3.org"
    And I press "Send me access links to my support tickets"
  Then 1 email should be delivered to "guest@ao3.org"
    And I should see "Email sent"
    And the email should contain "Support Ticket #1"
    And the email should contain "Support Ticket #2"
    And the email should contain "first"
    And the email should contain "second"

Scenario: if there are no tickets, the guest should be told
  Given a support ticket exists with email: "guest1@ao3.org"
    And a support ticket exists with email: "guest2@ao3.org"
    And all emails have been delivered
  When I am on the home page
    And I follow "Support Board"
    And I fill in "email" with "guest@ao3.org"
    And I press "Send me access links to my support tickets"
  Then 0 emails should be delivered
    And I should see "Sorry, no support tickets found for guest@ao3.org"

Scenario: guests can toggle notifications for individual tickets
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "first ticket"
    And I press "Create Support ticket"
  Then 1 email should be delivered to "guest@ao3.org"
    And all emails have been delivered
  When I press "Don't watch this ticket"
    And a user comments on support ticket 1
  Then 0 emails should be delivered to "guest@ao3.org"

  # turning off notifications for one shouldn't affect the other
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "second ticket"
    And I press "Create Support ticket"
  Then 1 email should be delivered to "guest@ao3.org"
    And all emails have been delivered
  When a user comments on support ticket 1
  Then 0 emails should be delivered to "guest@ao3.org"
  When a user comments on support ticket 2
  Then 1 emails should be delivered to "guest@ao3.org"

Scenario: guests can make their support tickets private
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
    And I check "Private"
  When I press "Create Support ticket"
  Then I should see "Access: Private"
  When I am logged in as "helpful"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should not see "Support Ticket #"
  When I am logged in as volunteer "oracle"
  When I follow "Support Board"
    And I follow "Open Support Tickets"
  Then I should see "Support Ticket #"

Scenario: guests can't make their private support tickets public
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
    And I check "Private"
  When I press "Create Support ticket"
  Then I should see "Access: Private"
    But I should not see "(Ticket will only be visible"

Scenario: guests can make their public support tickets private, even to people who already commented who should no longer get email
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "new ticket"
    And I press "Create Support ticket"
    And all emails have been delivered
  Given a user exists with login: "helpful"
    And "helpful" watches support ticket 1
    And "helpful" comments on support ticket 1
  Then 1 email should be delivered to "guest@ao3.org"
    And 1 email should be delivered to "helpful@ao3.org"
    And all emails have been delivered
  When I press "Make private"
    And I am logged in as "helpful"
    And I am on the page for the first support ticket
  Then I should see "Sorry, you don't have permission"
  When all emails have been delivered
    And a volunteer comments on support ticket 1
  Then 1 email should be delivered to "guest@ao3.org"
  And 0 emails should be delivered to "helpful@ao3.org"

Scenario: email to others shouldn't include the authorization
  Given a support ticket exists
    And all emails have been delivered
  When I am logged in as "helpful"
    And I am on the first support ticket page
    And I press "Watch this ticket"
  When I am logged out
    And a user comments on support ticket 1
  Then 1 email should be delivered to "helpful@ao3.org"
  When I click the first link in the email
  Then I should see "wrote"
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
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a user comments on support ticket 1
    And I reload the page
  When I select "someone wrote" from "Support Detail"
    And I press "This answer resolves my issue"
  Then I should see "Status: closed by owner"
    And I should see "someone wrote (accepted): blah blah"
  When I fill in "Reason" with "no it didn't"
    And I press "Reopen"
  Then I should see "Status: open"
    And I should see "someone wrote: blah blah"

Scenario: guests can (un)resolve their own support tickets using a support volunteer answer
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer comments on support ticket 1
    And I reload the page
  When I select "oracle (volunteer) wrote" from "Support Detail"
  When I press "This answer resolves my issue"
  Then I should see "Status: closed by owner"
    And I should see "oracle (volunteer) wrote (accepted): foo bar"
  When I fill in "Reason" with "no it didn't"
    And I press "Reopen"
  Then I should see "Status: open"
    And I should see "oracle (volunteer) wrote: foo bar"

Scenario: guests can view open code tickets, but not vote or comment
  Given a code ticket exists with id: 1
  When I am on the first code ticket page
  Then I should see "Status: open"
    And I should see "Votes: 0"
  But I should not see "Vote up"
    And I should not see "Details:"

Scenario: guests can view in progress code tickets, but not vote or comment
  Given a code ticket exists with id: 1
    And a volunteer exists with login: "oracle"
  When "oracle" takes code ticket 1
    And I am on the first code ticket page
  Then I should see "Status: taken by oracle"
    And I should see "Votes: 0"
  But I should not see "Vote up"
    And I should not see "Details:"

Scenario: guests can view closed code tickets, but not vote or comment
  Given a code ticket exists with id: 1
    And a volunteer exists with login: "oracle"
  When "oracle" takes code ticket 1
    And "oracle" resolves code ticket 1
  When I am on the first code ticket page
  Then I should see "Status: closed by oracle"
    And I should see "Votes: 0"
  But I should not see "Vote up"
    And I should not see "Details:"

Scenario: guests reading a draft FAQ can mark it as "this answered my question" (a FAQ vote)
  Given a faq exists with position: 1, title: "something interesting"
  When I am on the first faq page
  Then I should see "something interesting"
  When I press "This FAQ answered my question"
  Then I should see "Votes: 1"

Scenario: guests reading a posted FAQ can mark it as "this answered my question" (a FAQ vote)
  Given a posted faq exists with position: 1, title: "something else"
  When I am on the first faq page
  Then I should see "something else"
  When I press "This FAQ answered my question"
  Then I should see "Votes: 1"

Scenario: guests can view draft FAQs, but not comment
  Given a faq exists with position: 1, title: "nothing much"
  When I am on the first faq page
  Then I should see "nothing much"
    But I should not see "Details"

Scenario: guests can view posted FAQs, but not comment
  Given a posted faq exists with position: 1, title: "big faq"
  When I am on the first faq page
  Then I should see "big faq"
    But I should not see "Details"

Scenario: guests can comment on a draft FAQ when following a link from their own support ticket
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer creates a faq from support ticket 1
    And I reload the page
  Then I should see "Status: closed by oracle"
  When I follow "new faq"
    And I fill in "Details" with "this sounds good"
    And I press "Add details"
  Then I should see "support ticket owner wrote: this sounds good"

Scenario: guests can't comment on a posted FAQ when following a link from their own support ticket
  Given a posted faq exists
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer links support ticket 1 to faq 1
    And I reload the page
  Then I should see "Status: closed by oracle"
  When I follow "faq 1"
    Then I should not see "Details"

Scenario: guests can remove a link to a FAQ if they don't think it resolves their ticket
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer creates a faq from support ticket 1
    And I reload the page
  Then I should see "Status: closed by oracle"
    And I should see "new faq"
  When I fill in "Reason" with "FAQ not helpful"
    And I press "Reopen"
  Then I should see "Status: open"
    And I should not see "new faq" within "a"

Scenario: a posted faq should get a vote when linked from a guest support ticket
  Given a posted faq exists with position: 1, title: "slowness"
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer links support ticket 1 to faq 1
  When I am on the first faq page
  Then I should see "slowness"
    And I should see "Votes: 1"

Scenario: a posted faq should get a vote removed when unlinked from a guest support ticket
  Given a posted faq exists with position: 1, title: "slowness"
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer links support ticket 1 to faq 1
    And I reload the page
  When I fill in "Reason" with "FAQ not helpful"
    And I press "Reopen"
  When I am logged in as "oracle"
    And I am on the first faq page
  Then I should see "Votes: 0"

Scenario: a faq should get a vote from guest support tickets when it's posted
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
    And a volunteer creates a faq from support ticket 1
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I follow "FAQs waiting for comments"
    And I follow "new faq"
    And I press "Post"
  Then I should see "Votes: 1"

Scenario: a faq should not get a vote when it's posted if there are no linked support tickets
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer creates a faq from support ticket 1
    And I reload the page
  When I fill in "Reason" with "FAQ not helpful"
    And I press "Reopen"
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I follow "FAQs waiting for comments"
    And I follow "new faq"
    And I press "Post"
  Then I should see "Votes: 0"

Scenario: FAQs can be sorted by votes
  Given the following faqs exist
    | id | title   |
    | 1  | first   |
    | 2  | second  |
    | 3  | third   |
  And the following faq votes exist
    | faq_id | vote  |
    | 1      | 3     |
    | 2      | 7     |
    | 3      | 1     |
  When I am on the home page
    And I follow "Support Board"
    And I follow "FAQs waiting for comments"
  Then I should see "1: first"
    And I should see "2: second"
    And I should see "3: third"
  When I follow "Sort by vote count"
  Then I should see "1: second"
    And I should see "2: first"
    And I should see "3: third"

Scenario: code tickets can be sorted by votes
  Given the following code tickets exist
    | id | summary |
    | 1  | first   |
    | 2  | second  |
    | 3  | third   |
  And the following code votes exist
    | code_ticket_id | vote  |
    | 1              | 3     |
    | 2              | 7     |
    | 3              | 1     |
  When I am on the home page
    And I follow "Support Board"
    And I follow "Open Code Tickets (Known Issues)"
  Then I should see "1: Code Ticket #1 (3)"
    And I should see "2: Code Ticket #2 (7)"
    And I should see "3: Code Ticket #3 (1)"
  When I follow "Sort by vote count"
  Then I should see "1: Code Ticket #2 (7)"
    And I should see "2: Code Ticket #1 (3)"
    And I should see "3: Code Ticket #3 (1)"

