Feature: User's have pseuds (aliases or AKAs)

Scenario: default pseuds
  Given an activated user exists with login "sam"
  When I am on sam's user page
  Then I should see "sam's pseuds"
  When I follow "sam"

Scenario: support volunteer pseud
  Given an activated support volunteer exists with login "sam"
  When I am on sam's user page
  Then I should see "sam's pseuds"
  When I follow "sam(SV)"
