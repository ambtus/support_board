Feature: the support board as seen by guests

Scenario: what guests should (not) see
  Given I am on the home page
  When I follow "Support Board"
  Then I should see "Open a New Support Ticket"
    And I should see "Comments"
    And I should see "Frequently Asked Questions"
    And I should see "Known Issues"
    And I should see "Coming Soon"
    And I should see "Release Notes"
  # since they can't comment on them
  But I should not see "Open Support Tickets"
    And I should not see "Open Code Tickets"
  # since they aren't volunteers
  But I should not see "Admin attention"
    And I should not see "Claimed"
    And I should not see "Spam"
    And I should not see "Resolved"

Scenario: guests can view public tickets but not comment on them.
  Given a support ticket exists with summary: "publicly visible"
  When I go to the first support ticket page
  Then I should see "publicly visible"
    But I should not see "Add details"

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
    And I should see "Ticket owner wrote: For example"

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
  When a volunteer responds to support ticket 1
  Then 1 email should be delivered to "guest@ao3.org"
  When I click the first link in the email
  Then I should see "Add details"

Scenario: guests can continue to make other changes (persistent authorization)
  Given I am on the home page
  When I follow "Open a New Support Ticket"
  When I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
    And I fill in "Add details" with "For example, it took a minute for this page to render"
    And I press "Update Support ticket"
  Then I should see "Ticket owner wrote: For example"
  When I fill in "Add details" with "Never mind, I just found out my whole network is slow"
    And I press "Update Support ticket"
  Then I should see "Ticket owner wrote: Never mind"

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
    Then I should see "Add details"

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

Scenario: guests can enter an email address to have authorized links re-sent and can toggle notifications for individual tickets
  Given 2 support tickets exist
    And all emails have been delivered
  When I am on the home page
    And I follow "Support Board"
    And I fill in "email" with "guest@ao3.org"
    And I press "Send me access links to my support tickets"
  Then 1 email should be delivered to "guest@ao3.org"
    And I should see "Email sent"
    And all emails have been delivered

  When I click the first link in the email
    And I check "Turn off notifications"
    And I press "Update Support ticket"
  Then I should see "Support ticket updated"
    And I should see "Turn on notifications"
  When a user responds to support ticket 1
  Then 0 emails should be delivered to "guest@ao3.org"

  # turning off notifications for one shouldn't affect the other
  When a user responds to support ticket 2
  Then 1 email should be delivered to "guest@ao3.org"
    And all emails have been delivered

  # I'm still on support ticket 1's page
  When I check "Turn on notifications"
    And I press "Update Support ticket"
  Then I should see "Turn off notifications"

  # just toggling notifications shouldn't trigger an email. the ticket itself hasn't changed
  Then 0 emails should be delivered to "guest@ao3.org"
    And all emails have been delivered

  When a user responds to support ticket 1
  Then 1 email should be delivered to "guest@ao3.org"

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
    But I should not see "Private. (Ticket will only be visible"

Scenario: guests can make their public support tickets private, even to people who already commented who should no longer get email
  Given a support ticket exists
    And all emails have been delivered
  When I am logged in as "helpful"
    And I am on the first support ticket page
    And I fill in "Add details" with "Have you tried..."
    And I press "Update Support ticket"
  Then 1 email should be delivered to "guest@ao3.org"
  When I am logged out
    And I click the first link in the email
    And I check "Private"
    And I press "Update Support ticket"
  When I am logged in as "helpful"
    And I am on the first support ticket page
  Then I should see "Sorry, you don't have permission"
  When all emails have been delivered
    And a volunteer responds to support ticket 1
  Then 1 email should be delivered to "guest@ao3.org"
  And 0 emails should be delivered to "helpful@ao3.org"

Scenario: email to others shouldn't include the authorization
  Given a support ticket exists
    And all emails have been delivered
  When I am logged in as "helpful"
    And I am on the first support ticket page
    And I check "Turn on notifications"
    And I press "Update Support ticket"
  When I am logged out
    And a user responds to support ticket 1
  Then 1 email should be delivered to "helpful@ao3.org"
  When I click the first link in the email
  Then I should see "wrote"
    But I should not see "This answer resolves my issue"

Scenario: guests can (un)resolve their own support tickets using their own answers
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
    And I fill in "Add details" with "Never mind"
    And I press "Update Support ticket"
  Then I should see "Ticket owner wrote: Never mind"
  When I check "This answer resolves my issue"
    And I press "Update Support ticket"
  Then I should see "Status: Owner resolved"
    And I should see "Answered by Ticket owner: Never mind"
  When I uncheck "This answer resolves my issue"
   And I press "Update Support ticket"
  Then I should see "Status: Open"
    And I should see "Ticket owner wrote: Never mind"

Scenario: guests can (un)resolve their own support tickets using a user answer
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a user responds to support ticket 1
    And I reload the page
  When I check "This answer resolves my issue"
    And I press "Update Support ticket"
  Then I should see "Status: Owner resolved"
    And I should see "Answered by someone: blah blah"
  When I uncheck "This answer resolves my issue"
   And I press "Update Support ticket"
  Then I should see "Status: Open"
    And I should see "someone wrote: blah blah"

Scenario: guests can (un)resolve their own support tickets using a support volunteer answer
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer responds to support ticket 1
    And I reload the page
  When I check "This answer resolves my issue"
    And I press "Update Support ticket"
  Then I should see "Status: Owner resolved"
    And I should see "Answered by Support volunteer oracle: foo bar"
  When I uncheck "This answer resolves my issue"
   And I press "Update Support ticket"
  Then I should see "Status: Open"
    And I should see "volunteer oracle wrote: foo bar"

Scenario: guests can mark more than one answer as having resolved their ticket
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
    And I fill in "Add details" with "Never mind"
    And I press "Update Support ticket"
    And a user responds to support ticket 1
  When a volunteer responds to support ticket 1
    And I reload the page
  When I check "support_ticket_support_details_attributes_0_resolved_ticket"
    And I check "support_ticket_support_details_attributes_1_resolved_ticket"
    And I check "support_ticket_support_details_attributes_2_resolved_ticket"
    And I press "Update Support ticket"
  Then I should see "Status: Owner resolved"
    And I should see "Answered by Ticket owner: Never mind"
    And I should see "Answered by someone: blah blah"
    And I should see "Answered by Support volunteer oracle: foo bar"
  When I uncheck "support_ticket_support_details_attributes_0_resolved_ticket"
  When I uncheck "support_ticket_support_details_attributes_1_resolved_ticket"
   And I press "Update Support ticket"
  Then I should see "Status: Owner resolved"
    And I should see "Ticket owner wrote: Never mind"
    And I should see "someone wrote: blah blah"
    And I should see "Answered by Support volunteer oracle: foo bar"
  When I uncheck "support_ticket_support_details_attributes_2_resolved_ticket"
   And I press "Update Support ticket"
  Then I should see "Status: Open"
    And I should see "volunteer oracle wrote: foo bar"

Scenario: guests can view open code tickets, but not vote or respond
  Given a code ticket exists with id: 1
  When I am on the first code ticket page
  Then I should see "Status: Open"
    And I should see "Votes: 0"
  But I should not see "Vote up"
    And I should not see "Add details"

Scenario: guests can view in progress code tickets, but not vote or respond
  Given a code ticket exists with id: 1
    And a volunteer exists with login: "oracle"
  When "oracle" takes code ticket 1
    And I am on the first code ticket page
  Then I should see "Status: In progress"
    And I should see "Votes: 0"
  But I should not see "Vote up"
    And I should not see "Add details"

Scenario: guests can view closed code tickets, but not vote or respond
  Given a code ticket exists with id: 1
    And a volunteer exists with login: "oracle"
  When "oracle" takes code ticket 1
    And "oracle" resolves code ticket 1
  When I am on the first code ticket page
  Then I should see "Status: Closed"
    And I should see "Votes: 0"
  But I should not see "Vote up"
    And I should not see "Add details"

Scenario: guests reading a FAQ can mark it as "this answered my question" (a FAQ vote)
  Given an archive faq exists with posted: true
  When I am on the first archive faq page
  Then I should see "faq 1"
  When I press "This FAQ answered my question"
  Then I should not see "Votes: 1"
  When I am logged in as volunteer "oracle"
    And I am on the first archive faq page
  Then I should see "Votes: 1"

Scenario: guests can view posted FAQs, but not comment
  Given an archive faq exists with posted: true
  When I am on the first archive faq page
  Then I should see "faq 1"
    But I should not see "Add comment"

Scenario: guests can view draft FAQs, but not comment
  Given an archive faq exists with posted: false
  When I am on the first archive faq page
  Then I should see "faq 1"
    But I should not see "Add comment"

Scenario: guests can comment on a draft FAQ when following a link from their own support ticket
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer creates a faq from support ticket 1
    And I reload the page
  Then I should see "Status: Linked to FAQ by oracle"
  When I follow "1: faq 1"
    And I fill in "Add comment" with "this sounds good"
    And I press "Update Archive faq"
  Then I should see "Support ticket owner wrote: this sounds good"

Scenario: guests can't comment on a posted FAQ when following a link from their own support ticket
  Given an archive faq exists with posted: true, position: 1
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer links support ticket 1 to faq 1
    And I reload the page
  Then I should see "Status: Linked to FAQ by oracle"
  When I follow "1: faq 1"
    Then I should not see "Add comment"

Scenario: guests can remove a link to a FAQ if they don't think it resolves their ticket
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer creates a faq from support ticket 1
    And I reload the page
  Then I should see "Status: Linked to FAQ by oracle"
    And I should see "1: faq 1"
  When I uncheck "linked to FAQ"
    And I press "Update Support ticket"
  Then I should see "Status: In progress"
    And I should not see "1: faq 1"

Scenario: a posted archive faq should get a vote when linked from a guest support ticket
  Given an archive faq exists with posted: true, position: 1
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer links support ticket 1 to faq 1
  When I am logged in as "oracle"
    And I am on the first archive faq page
  Then I should see "Votes: 1"

Scenario: a posted archive faq should get a vote removed when unlinked from a guest support ticket
  Given an archive faq exists with posted: true, position: 1
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer links support ticket 1 to faq 1
    And I reload the page
  When I uncheck "linked to FAQ"
    And I press "Update Support ticket"
  When I am logged in as "oracle"
    And I am on the first archive faq page
  Then I should see "Votes: 0"

Scenario: an archive faq should get a vote from guest support tickets when it's posted
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
    And a volunteer creates a faq from support ticket 1
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I follow "Unposted FAQs"
    And I follow "1: faq 1"
    And I press "Post"
  Then I should see "Votes: 1"

Scenario: an archive faq should not get a vote when it's posted if there are no linked support tickets
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When a volunteer creates a faq from support ticket 1
    And I reload the page
  When I uncheck "linked to FAQ"
    And I press "Update Support ticket"
  When I am logged in as support admin "incharge"
    And I follow "Support Board"
    And I follow "Unposted FAQs"
    And I follow "1: faq 1"
    And I press "Post"
  Then I should see "Votes: 0"

