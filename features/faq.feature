Feature: faqs are for answering user's questions in an official and standard way
  Draft faqs can be commented on before they are posted
  All faqs can be voted on

Scenario: support admins can post drafts (aka RFCs)
  When I am logged in as "bofh"
  When I am on the support page
    And I follow "Frequently Asked Questions"
  Then I should not see "why we don't have enough ZPMs"
  When I am on the support page
    And I follow "drafts" within "#faqs"
    And I follow "why we don't have enough ZPMs"
    And I press "Post"
  When I am on the support page
    And I follow "Frequently Asked Questions"
  Then I should see "why we don't have enough ZPMs"

Scenario: support admins can unpost FAQs
  When I am logged in as "bofh"
  When I am on the support page
    And I follow "Frequently Asked Questions"
    And I follow "where to find salt"
    And I fill in "Reason" with "needs more work"
    And I press "Reopen for comments"
  When I am on the support page
    And I follow "Frequently Asked Questions"
  Then I should not see "where to find salt"
  When I am on the support page
    And I follow "drafts" within "#faqs"
  Then I should see "where to find salt"

Scenario: when a draft FAQ is marked posted, the comments are no longer visible, but aren't destroyed
  When I am logged in as "rodney"
  When I am on the support page
    And I follow "drafts" within "#faqs"
    And I follow "why we don't have enough ZPMs"
    And I fill in "Details" with "please include"
    And I press "Add details"
  When I am logged in as "sam"
    And I am on the page for faq 2
    And I fill in "Details" with "don't forget"
    And I press "Add details"
  Then I should see "rodney (volunteer) wrote: please include"
    And I should see "sam (volunteer) wrote: don't forget"
  When I am logged in as "bofh"
    And I am on the page for faq 2
    And I press "Post"
  Then I should see "why we don't have enough ZPMs"
    But I should not see "please include"
    And I should not see "don't forget"
  When I fill in "Reason" with "Oops, wrong one"
    And I press "Reopen for comments"
  Then I should see "rodney (volunteer) wrote: please include"
    And I should see "sam (volunteer) wrote: don't forget"

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
  When "sam" creates a faq from the last support ticket
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
  When "sam" links the last support ticket to faq 1
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
  When "rodney" links the last support ticket to faq 2
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
  When "blair" creates a faq from the last support ticket
    And I reload the page
  When I fill in "Reason" with "FAQ not helpful"
    And I press "Reopen"
  Then I should see "Status: open"
  When I am on the page for the last faq
  Then I should see "Votes: 0"

Scenario: FAQs can be sorted by votes
  When I am on the home page
    And I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should see "1: where to find salt (0)"
    And I should see "2: what's DADT? (1)"
    And I should see "3: how to recover your password (5)"
  When I follow "Sort by vote count"
  Then I should see "3: where to find salt (0)"
    And I should see "2: what's DADT? (1)"
    And I should see "1: how to recover your password (5)"

Scenario: users can view posted FAQs, but not comment
  Given I am logged in as "jim"
  When I am on the page for faq 1
  Then I should see "where to find salt"
    But I should not see "Details"

Scenario: users can comment on a draft FAQ
  Given I am logged in as "jim"
  When I am on the page for faq 2
  Then I should see "why we don't have enough ZPMs"
    And I fill in "Details" with "What's a ZPM?"
    And I press "Add details"
  Then I should see "jim wrote: What's a ZPM?"

Scenario: users reading a draft FAQ can mark it as "this answered my question" (a FAQ vote)
  Given I am logged in as "dean"
  When I am on the page for faq 2
  Then I should see "Votes: 0"
  When I press "This FAQ answered my question"
  Then I should see "Votes: 1"

Scenario: users reading a posted FAQ can mark it as "this answered my question" (a FAQ vote)
  Given I am logged in as "dean"
  When I am on the page for faq 1
  Then I should see "Votes: 0"
  When I press "This FAQ answered my question"
  Then I should see "Votes: 1"

Scenario: a posted faq should get a vote when linked from a user support ticket
  When I am on the page for faq 5
  Then I should see "what's a sentinel"
    And I should see "Votes: 1"

Scenario: users can remove a link to a draft FAQ if they don't think it resolves their ticket. also removes the vote.
  Given I am logged in as "jim"
  And I am on the page for support ticket 6
  Then I should see "closed by blair what's a sentinel?"
  When I fill in "Reason" with "I am not a freak!"
    And I press "Reopen"
  Then I should see "Status: open"
    And I should not see "what's a sentinel?" within "a"
  When I am on the page for faq 5
    Then I should see "what's a sentinel"
    And I should see "Votes: 0"

Scenario: users can remove a link to a posted FAQ if they don't think it resolves their ticket. also removes the vote.
  Given I am logged in as "john"
  When I am on the page for faq 4
  Then I should see "Votes: 5"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I select "closed" from "Status"
    And I fill in "Opened by" with "john"
    And I press "Filter"
    And I follow "Support Ticket #5"
  Then I should see "closed by rodney how to recover your password"
  When I fill in "Reason" with "Didn't work"
    And I press "Reopen"
  Then I should see "Status: open"
    And I should not see "how to recover your password" within "a"
  When I am on the page for faq 4
  Then I should see "Votes: 4"

# TODO
Scenario: volunteers can send email to an admin asking them to post a faq
