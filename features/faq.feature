Feature: faqs are for answering user's questions in an official and standard way
  Draft faqs can be commented on before they are posted
  All faqs can be voted on

Scenario: volunteers can create draft faqs
  When I am logged in as "sam"
  When I am on the support page
    And I follow "create new faq"
    And I fill in "Summary" with "my new faq"
    And I fill in "Content" with "some interesting stuff"
    And I press "Create Faq"
  Then I should see "Faq created"

Scenario: support admins can post drafts (aka RFCs)
  When I am logged in as "sidra"
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
  When I am logged in as "sidra"
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
    And I fill in "content" with "please include"
    And I press "Add details"
  When I am logged in as "sam"
    And I am on the page for faq 2
    And I fill in "content" with "don't forget"
    And I press "Add details"
  Then I should see "rodney (volunteer) wrote: please include"
    And I should see "sam (volunteer) wrote: don't forget"
  When I am logged in as "sidra"
    And I am on the page for faq 2
    And I press "Post"
  Then I should see "why we don't have enough ZPMs"
    But I should not see "please include"
    And I should not see "don't forget"
  When I fill in "Reason" with "Oops, wrong one"
    And I press "Reopen for comments"
  Then I should see "rodney (volunteer) wrote: please include"
    And I should see "sam (volunteer) wrote: don't forget"

Scenario: guests reading a posted FAQ can mark it as "this answered my question" (a FAQ vote)
  When I am on the page for faq 1
  Then I should see "0 votes"
  Then I should see "where to find salt"
  When I press "This FAQ answered my question"
  Then I should see "1 votes"

Scenario: guests can comment on a draft FAQ when following a link from their own support ticket
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "new question"
    And I press "Create Support ticket"
  When "sam" creates a faq from the last support ticket
    And I reload the page
  Then I should see "[answered by FAQ new faq]"
  When I follow "new faq"
    And I fill in "content" with "this sounds good"
    And I press "Add details"
  Then I should see "ticket owner wrote: this sounds good"

Scenario: an existing faq should get two votes when linked from a guest support ticket
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When "rodney" links support ticket 1 to faq 2
  When "rodney" posts faq 2
  When I am on the page for faq 2
    And I should see "2 votes"

Scenario: a faq should get 2 votes when it's created from a guest support ticket
  Given I am on the home page
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
    And "rodney" creates a faq from support ticket 1
    And "rodney" posts the last faq
  When I am on the page for the last faq
  Then I should see "2 votes"

Scenario: an existing faq should get a vote removed when unlinked from a guest support ticket
  When I am on the page for faq 1
  Then I should see "0 votes"
  When I follow "Open a New Support Ticket"
    And I fill in "Email" with "guest@ao3.org"
    And I fill in "Summary" with "Archive is very slow"
  When I press "Create Support ticket"
  When "rodney" links the last support ticket to faq 1
    And I reload the page
  Then I should see "[answered by FAQ where to find salt]"
  When I fill in "Reason" with "what's that got to do with it"
    And I press "Reopen"
  Then I should see "[open]"
    And I should not see "where to find salt"
  When I am on the page for faq 1
  Then I should see "0 votes"

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
  Then I should see "[open]"
  When "rodney" posts the last faq
    And I am on the page for the last faq
  Then I should see "0 votes"

Scenario: FAQs can be sorted by votes
  When I am on the home page
    And I follow "Support Board"
    And I follow "Frequently Asked Questions"
  Then I should see "where to find salt (0 votes)" within "#0"
  When I follow "Sort by vote count"
  Then I should see "how to recover your password (6 votes)" within "#0"
  When I follow "Sort by position"
  Then I should see "where to find salt (0 votes)" within "#0"

Scenario: users can view posted FAQs
  Given I am logged in as "jim"
  When I am on the page for faq 1
  Then I should see "where to find salt"

Scenario: users can comment on a draft FAQ
  Given I am logged in as "jim"
  When I am on the page for faq 2
  Then I should see "why we don't have enough ZPMs"
    And I fill in "content" with "What's a ZPM?"
    And I press "Add details"
  Then I should see "jim wrote: What's a ZPM?"

Scenario: users reading a posted FAQ can mark it as "this answered my question" (a FAQ vote)
  Given I am logged in as "dean"
  When I am on the page for faq 1
  Then I should see "0 votes"
  When I press "This FAQ answered my question"
  Then I should see "1 votes"

Scenario: users can remove a link to a draft FAQ if they don't think it resolves their ticket. also removes the vote.
  Given I am logged in as "jim"
  And I am on the page for support ticket 6
  Then I should see "[answered by FAQ what's a sentinel?]"
  When I fill in "Reason" with "I am not a freak!"
    And I press "Reopen"
  Then I should see "[open]"
    And I should not see "what's a sentinel?" within "a"
  When "sidra" posts faq 5
    And I am on the page for faq 5
    Then I should see "what's a sentinel"
    And I should see "0 votes"

Scenario: users can remove a link to a posted FAQ if they don't think it resolves their ticket. also removes the vote.
  Given I am logged in as "john"
  When I am on the page for faq 4
  Then I should see "6 votes"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I select "closed" from "Status"
    And I fill in "Opened by" with "john"
    And I press "Filter"
    And I follow "Support Ticket #5"
  Then I should see "answered by FAQ how to recover your password"
  When I fill in "Reason" with "Didn't work"
    And I press "Reopen"
  Then I should see "[open]"
    And I should not see "how to recover your password" within "a"
  When I am on the page for faq 4
  Then I should see "4 votes"



# TODO
Scenario: faqs can be translated
Scenario: faqs can be filtered by language

