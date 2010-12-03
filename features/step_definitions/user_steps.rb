Given /^an activated user exists with login "([^"]*)"$/ do |login|
  user = User.find_by_login(login)
  user = Factory.create(:user, :login => login) unless user
  user.activate
end

Given /^I am logged in as "([^"]*)"$/ do |login|
  visit logout_path
  Given %{an activated user exists with login "#{login}"}
  visit root_path
  fill_in "User name", :with => login
  fill_in "Password", :with => "secret"
  check "Remember me"
  click_button "Log in"
  assert UserSession.find
end

Given /the following activated users? exists?/ do |table|
  table.hashes.each do |hash|
    user = Factory.create(:user, hash)
    user.activate
  end
end

Given /^I am logged out$/ do
  visit logout_path
  assert !UserSession.find
end
