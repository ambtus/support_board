Given /^I am logged in as "([^"]*)"$/ do |login|
  # " reset quotes for color
  visit logout_path
  user = User.find_by_login(login) || Factory.create(:user, :login => login)
  visit root_path
  fill_in "User name", :with => login
  fill_in "Password", :with => "secret"
  check "Remember me"
  click_button "Log in"
  assert UserSession.find
end

Given /^I am logged out$/ do
  visit logout_path
  assert !UserSession.find
end
