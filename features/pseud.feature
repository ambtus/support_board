Feature: User's have pseuds (aliases or AKAs)

Scenario: default pseuds
  Given a user exists with login: "sam"
  When I am on sam's user page
    And I follow "sam's pseuds"
  Then I should see "sam (default pseud)"

Scenario: volunteer pseud
  Given a volunteer exists with login: "sam"
  When I am on sam's user page
    And I follow "sam's pseuds"
  Then I should see "sam (default pseud) (support pseud)"
  When "sam" has a support pseud "oracle"
    And I reload the page
  Then I should see "sam (default pseud)"
  Then I should see "oracle (support pseud)"
    But I should not see "sam (default pseud) (support pseud)"
