Feature: archive users open support tickets when they need help

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
    And I fill in "Details" with "For example, it took a minute for this page to render"
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
    And I should not see "Details can't be blank"
  When I fill in "Summary" with "Archive is very slow"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Summary: Archive is very slow"
    And I should not see "User: dean"
  And 1 email should be delivered to "dean@ao3.org"

Scenario: users can create private support tickets
  Given I am logged in as "dean"
  When I follow "Open a New Support Ticket"
    And I fill in "Summary" with "Why are there no results when I search for wattersports?"
    And I check "Private. (Ticket will only be visible to owner and official Support volunteers. This cannot be undone.)"
  When I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Summary: Why are there no results when I search for wattersports?"
    And I should see "Access: Private"
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
    And I fill in "Details" with "For example"
    And I uncheck "Anonymous"
    And I press "Create Support ticket"
  Then I should see "Support ticket created"
    And I should see "Summary: Archive is very slow"
    And I should see "dean wrote: For example"
    And I should see "User: dean"

# FIXME
Scenario: ignore if enter an empty comment  (probably meant to click a different button)
