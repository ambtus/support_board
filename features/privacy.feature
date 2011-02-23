Feature: privacy related scenarios

Scenario: guests can't access private tickets even with a direct link.
  When I am on the page for support ticket 2
  Then I should see "Sorry, you don't have permission"
    And I should not see "a personal problem"

Scenario: support admins (only - privacy issues) can see the authenticity_token, and originating IP
  When I am logged in as "sidra"
    And I am on the page for support ticket 1
  Then I should see "some problem"
    And I should see "authenticity token: OogoGee7oosheeciogie"
    And I should see "remote IP: 72.14.204.103"

Scenario: guests can make their public support tickets private, even to users who already commented who should no longer get email
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
  Then 1 email should be delivered to "guest@ao3.org"
    And the email should contain "authentication_code"
  Then 1 email should be delivered to "jim@ao3.org"
    And the email should not contain "authentication_code"

Scenario: users can't access private tickets
  Given I am logged in as "dean"
  When I am on the page for support ticket 2
  Then I should see "Sorry, you don't have permission"
  When I am on the page for support ticket 4
  Then I should see "Sorry, you don't have permission"

Scenario: links to support tickets a user is watching are private
  When I am logged in as "jim"
    And I am on the support page
  And I follow "Support tickets I am watching"
  Then I should be at the url /support_tickets?watching=true
    And I should see "Support Ticket #7"
    And I should see "where can I find a guide"
    But I should not see "Support Ticket #3"
  When I am logged out
    And I am on the support page
  Then I should not see "Support tickets I am watching"
  When I go to /support_tickets?watching=true
  Then I should see "Please log in"
    And I should not see "Support Ticket #7"
  When I am logged in as "sam"
    And I go to /support_tickets?watching=true
  Then I should see "Support Ticket #3"
    And I should see "Support Ticket #8"
    But I should not see "Support Ticket #7"

Scenario: links to code tickets a user is watching are private
  When I am logged in as "blair"
    And I am on the support page
  And I follow "Code tickets I am watching"
  Then I should be at the url /code_tickets?watching=true
    And I should see "Code Ticket #5"
    And I should see "find a sentinel"
    But I should not see "Code Ticket #3"
  When I am logged out
    And I am on the support page
  Then I should not see "Code tickets I am watching"
  When I go to /code_tickets?watching=true
  Then I should see "Please log in"
    And I should not see "Code Ticket #5"
  When I am logged in as "sam"
    And I go to /code_tickets?watching=true
  Then I should see "Code Ticket #2"
    And I should not see "Code Ticket #5"

Scenario: users can hide their name after creation
  Given I am logged in as "dean"
  And I am on the page for support ticket 3
  Then I should see "(dean)"
    And I should see "dean wrote: and the holy water"
  When I press "Hide my user name"
  Then I should not see "(dean)"
    And I should see "ticket owner wrote: and the holy water"

Scenario: users can unhide their name after creation
  Given I am logged in as "john"
  And I am on the page for support ticket 4
  Then I should not see "(john)"
    And I should see "ticket owner wrote: the sooner the better"
  When I press "Display my user name"
  Then I should see "(john [Private])"
    And I should see "john wrote: the sooner the better"

Scenario: user's tickets should be available by filtering, respecting private and show user name settings
  Given I am logged out
    And I am on the support page
    And I follow "Support Tickets"
  Then I should see "Support Ticket #1 some problem (a guest) [open]"
    And I should see "Support Ticket #3 where's the salt? (dean) [taken by sam]"
    And I should see "Support Ticket #7 where can I find a guide (a user) [waiting for a code fix find a sentinel]"
    And I should see "Support Ticket #8 where are you, dean? (sam) [open]"
    And I should see "Support Ticket #9 where are you, castiel? (a user) [taken by sidra]"
    And I should see "Support Ticket #21 please give me volunteer status (dean) [waiting for an admin]"
  # shouldn't see private tickets
  But I should not see "Support Ticket #4"
    And I should not see "Support Ticket #16"

  When I fill in "Opened by" with "john"
    And I press "Filter"
  Then I should see "0 Found"
  When I fill in "Opened by" with "dean"
    And I press "Filter"
  Then I should see "2 Found"
    And I should see "Support Ticket #3"
    And I should see "Support Ticket #21"
  When I fill in "Opened by" with "jim"
    And I press "Filter"
  Then I should see "0 Found"

  Given I am logged in as "jim"
    And I am on the support page
    And I follow "Support Tickets"
  When I fill in "Opened by" with "john"
    And I press "Filter"
  Then I should see "0 Found"
  When I fill in "Opened by" with "jim"
    And I press "Filter"
  Then I should see "2 Found"
    And I should see "Support Ticket #7"
    And I should see "Support Ticket #16"

  Given I am logged in as "dean"
    And I am on the support page
    And I follow "Support Tickets"
  When I fill in "Opened by" with "jim"
    And I press "Filter"
  Then I should see "0 Found"
  When I fill in "Opened by" with "dean"
    And I press "Filter"
  Then I should see "3 Found"
    And I should see "Support Ticket #3"
    And I should see "Support Ticket #9"
    And I should see "Support Ticket #21"

  Given I am logged in as "sam"
    And I am on the support page
    And I follow "Support Tickets"
  Then I should see "Support Ticket #1"
    And I should see "Support Ticket #3"
    And I should see "Support Ticket #4"
    And I should see "Support Ticket #7"
    And I should see "Support Ticket #8"
    And I should see "Support Ticket #9"
    And I should see "Support Ticket #16"

  When I fill in "Opened by" with "john"
    And I press "Filter"
  Then I should see "0 Found"
  When I fill in "Opened by" with "dean"
    And I press "Filter"
  Then I should see "2 Found"
    And I should see "Support Ticket #3"
    And I should see "Support Ticket #21"
  When I fill in "Opened by" with "jim"
    And I press "Filter"
  Then I should see "0 Found"

Scenario: support board volunteers can access and take private tickets
  Given I am logged in as "blair"
  When I follow "Support Board"
    And I follow "Support Tickets"
    And I follow "Support Ticket #16"
    Then I should see "Private"
  When I press "Take"
  Then I should see "taken by blair"

Scenario: support board volunteers can make tickets private
  When I am logged in as "blair"
    And I am on the page for support ticket 1
  Then I should see "Ticket will only be visible to"
    And I press "Make private"
  Then I should see "Private"

Scenario: visibility on the comment board
  # logged out
  When I am logged out
    And I follow "Support Board"
    And I follow "Comments"
  Then I should not see "happy@ao3.org"
    And I should not see "newbie"
    And I should not see "john"
    And I should not see "thanks for fixing it"
    And I should not see "thank you for helping"
  But I should see "#10 (a guest) You guys rock!"
    And I should see "#12 (a user) you guys suck!"
    And I should see "#14 (dean) I'm leaving fandom forever!"

  # logged in as support volunteer can see private comments
  When I am logged in as "sam"
    And I follow "Support Board"
    And I follow "Comments"
  Then I should not see "happy@ao3.org"
    And I should not see "newbie"
  But I should see "#10 (a guest) You guys rock!"
    And I should see "#11 (a guest [Private]) thanks for fixing it"
    And I should see "#12 (a user) you guys suck!"
    And I should see "#13 (a user [Private]) I like the archive"
    And I should see "#14 (dean) I'm leaving fandom forever!"
    And I should see "#15 (jim [Private]) thank you for helping"

Scenario: support volunteers (only - possible privacy issues) can see the referring URL
  When I am on the page for support ticket 8
  Then I should see "where are you, dean?"
    But I should not see "referring url: /users/dean"
  When I am logged in as "blair"
    And I am on the page for support ticket 8
  Then I should see "where are you, dean?"
    And I should see "referring url: /users/dean"

Scenario: support volunteers can't see the referring URL for anonymous tickets
  When I am logged in as "blair"
  When I am on the page for support ticket 4
  Then I should see "repeal DADT"
    But I should not see "referring url: /faqs/3"
  When I am logged in as "john"
    And I am on the page for support ticket 4
    And I press "Display my user name"
  When I am logged in as "blair"
    And I am on the page for support ticket 4
    Then I should see "referring url: /faqs/3"

Scenario: links to code tickets they're watching, private
  Given "jim" watches code ticket 1
    And "jim" watches code ticket 2
    And "jim" watches code ticket 5
  When I am logged in as "jim"
    And I follow "Support Board"
    And I follow "Code tickets I am watching"
  Then I should see "Code Ticket #1"
    And I should see "Code Ticket #2"
    And I should see "Code Ticket #5"
    But I should not see "Code Ticket #3"


# TODO
Scenario: guests and users should not be able to see private details (support, code or faq)
Scenario: guests and users should not receive notifications when private details are added (support, code or faq)
Scenario: guest and user notifications should not include private details (support, code or faq)
Scenario: support volunteers can be unofficial after the support ticket is unowned if they opened the ticket (they are the owner)
Scenario: the show ticket as support volunteer needs a corresponding show ticket as owner

