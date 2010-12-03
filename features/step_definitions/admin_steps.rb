Given /^an activated admin exists with login "([^"]*)"$/ do |login|
  admin = Admin.find_by_login(login)
  admin = Factory.create(:admin, :login => login) unless admin
  admin.activate
end

Given /^I am logged in as admin "([^"]*)"$/ do |login|
  Given %{an activated admin exists with login "#{login}"}
  visit admin_login_path
  fill_in "Admin name", :with => login
  fill_in "Admin Password", :with => "secret"
  check "Remember me"
  click_button "Log in as Admin"
  assert AdminSession.find
end
