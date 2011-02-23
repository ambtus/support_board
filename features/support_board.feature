Feature: the support board main page is where you start and can find all related information

Scenario: guests can enter an email address to have authorized links re-sent
  When I am on the home page
    And I follow "Support Board"
    And I fill in "email" with "guest@ao3.org"
    And I press "Send me access links to my support tickets"
  Then 1 email should be delivered to "guest@ao3.org"
    And I should see "Email sent"
    And the email should contain "some problem"
    And the email should contain "authentication_code=060d053559c7d87432b6"
    And the email should contain "a personal problem"
    And the email should contain "authentication_code=4a45d393856158dc10d9"

Scenario: if there are no tickets, the guest should be told
  When I am on the home page
    And I follow "Support Board"
    And I fill in "email" with "noob@ao3.org"
    And I press "Send me access links to my support tickets"
  Then 0 emails should be delivered
    And I should see "Sorry, no support tickets found for noob@ao3.org"

Scenario: guests can open a new support ticket
  When I am on the support page
    And I follow "Open a New Support Ticket"
    Then I should see "Email"

Scenario: guests can see links to frequently asked questions
  When I am on the support page
    And I follow "Frequently Asked Questions"
    And I follow "where to find salt"
  Then I should see "in the sea."

Scenario: guests can see links to release notes
  When I am on the support page
    And I follow "Release Notes"
    And I follow "1.0"
  Then I should see "Code Ticket #6"

Scenario: guests can see links to code tickets
  When I am on the support page
    And I follow "Open Code Tickets (Known Issues)"
    And I follow "Code Ticket #5"
  Then I should see "Code Commit #4"

Scenario: guests can see links to public support tickets
  When I am on the support page
    And I follow "Support Tickets"
    And I follow "Support Ticket #1"
  Then I should see "some problem"

Scenario: guests can see links to posted support tickets
  When I am on the support page
    And I follow "Comments"
  Then I should see "#10 (a guest) You guys rock!"

Scenario: users can see a link to support tickets they are interested in
  When I am logged in as "dean"
  When I am on the support page
    And I follow "Support tickets I am watching"
  Then I should see "Support Ticket #21"

Scenario: users can see a link to code tickets they are interested in
  When I am logged in as "john"
  When I am on the support page
    And I follow "Code tickets I am watching"
  Then I should see "Code Ticket #4"

Scenario: users can see a link to support tickets they opened
  When I am logged in as "john"
  When I am on the support page
    And I follow "Support tickets I opened"
  Then I should see "Support Ticket #20"

Scenario: volunteers can see a link to support tickets they owned
  When I am logged in as "sam"
  When I am on the support page
    And I follow "Support tickets I own"
  Then I should see "Support Ticket #3"

Scenario: volunteers can see more links
  When I am logged in as "sam"
  When I am on the support page
  Then I should see "create new faq"
    And I should see "create new code ticket"
    And I should see "create new release note"
    And I should see "drafts"

Scenario: admins can see more stuff
  When I am logged in as "rodney"
  When I am on the support page
  Then I should see "Unmatched Commits"
    And I should see "Admin"
    And I should see "2.1"



# TODO
Scenario: search or link to search page as well as filter from the index pages


