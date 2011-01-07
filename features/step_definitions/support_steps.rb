# overriding application.rb
# will throw a warning
Given /^the current SupportBoard version is "([^"]*)"$/ do |revision|
  # " reset quotes for color
  SupportBoard::REVISION_NUMBER = revision.to_i
end


# creating and logging in as volunteers and admins

Given /^I am logged in as volunteer "([^"]*)"$/ do |login|
  # " reset quotes for color
  visit logout_path
  user = User.find_by_login(login) || Factory.create(:volunteer, :login => login)
  assert user.support_volunteer?
  visit root_path
  fill_in "User name", :with => login
  fill_in "Password", :with => "secret"
  check "Remember me"
  click_button "Log in"
  assert UserSession.find
end

Given /^I am logged in as support admin "([^"]*)"$/ do |login|
  # " reset quotes for color
  visit logout_path
  user = User.find_by_login(login) || Factory.create(:support_admin, :login => login)
  assert user.support_admin?
  visit root_path
  fill_in "User name", :with => login
  fill_in "Password", :with => "secret"
  check "Remember me"
  click_button "Log in"
  assert UserSession.find
end

Given /^"([^"]*)" has a support identity "([^"]*)"$/ do |login, name|
  user = User.find_by_login(login)
  assert_not_nil user
  assert user.support_identity.update_attribute(:name, name)
end

# generic user actions on tickets

Given /^a user comments on support ticket (\d+)$/ do |number|
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login("someone")
  user = Factory.create(:user, :login => "someone") unless user
  User.current_user = user
  assert ticket.comment!("blah blah")
end

# generic volunteer actions on tickets

Given /^a volunteer comments on support ticket (\d+)$/ do |number|
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login("oracle")
  unless user
    Given %{a volunteer exists with login: "oracle"}
    user = User.find_by_login("oracle")
  end
  assert user.support_volunteer?
  User.current_user = user
  assert ticket.comment!("foo bar")
end

Given /^a posted faq exists$/ do
  Given %{a faq exists}
  Given %{a support admin exists with login: "bofh"}
  faq = Faq.first
  User.current_user = User.find_by_login("bofh")
  faq.post!
end

Given /^a posted faq exists with position: (\d+), title: "([^"]*)"$/ do |number, title|
  # " reset quotes for color
  Given %{a faq exists with position: #{number}, title: "#{title}"}
  Given %{a support admin exists with login: "bofh"}
  faq = Faq.find_by_position(number)
  User.current_user = User.find_by_login("bofh")
  faq.post!
end


When /^a volunteer creates a faq from support ticket (\d+)$/ do |number|
  ticket = SupportTicket.all[number.to_i - 1]
  Given %{a volunteer exists with login: "oracle"}
  User.current_user = User.find_by_login("oracle")
  assert faq = ticket.answer!
  faq.update_attribute(:title, "new faq")
end

When /^a volunteer links support ticket (\d+) to faq (\d+)$/ do |arg1, arg2|
  assert ticket = SupportTicket.all[arg1.to_i - 1]
  assert faq = Faq.find_by_position(arg2.to_i)
  Given %{a volunteer exists with login: "oracle"}
  User.current_user = User.find_by_login("oracle")
  assert ticket.answer!(faq.id)
end

Given /^a volunteer comments on code ticket (\d+)$/ do |number|
  ticket = CodeTicket.all[number.to_i - 1]
  Given %{a volunteer exists with login: "oracle"}
  User.current_user =  User.find_by_login("oracle")
  assert ticket.comment!("foo bar")
end

# named user actions on tickets.
# create the support identity they'd get working through the web interface

Given /^"([^"]*)" comments on support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  assert ticket.comment!("foo bar")
end

Given /^"([^"]*)" watches support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  # needs a support identity which they would have gotten if they've visited the page
  User.current_user.support_identity
  assert ticket.watch!
end

Given /^"([^"]*)" accepts a comment on support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  detail = ticket.support_details.where(:resolved_ticket => false).first
  assert ticket.accept!(detail.id)
end

Given /^"([^"]*)" takes support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  assert ticket.take!
end

Given /^"([^"]*)" posts support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  assert ticket.post!
end

When /^"([^"]*)" creates a faq from support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  assert faq = ticket.answer!
  faq.update_attribute(:title, "new faq")
end

When /^"([^"]*)" creates a code ticket from support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  assert ticket.needs_fix!
end

When /^"([^"]*)" links support ticket (\d+) to code ticket (\d+)$/ do |login, arg1, arg2|
  # " reset quotes for color
  assert ticket = SupportTicket.all[arg1.to_i - 1]
  assert code = CodeTicket.all[arg2.to_i - 1]
  User.current_user = User.find_by_login(login)
  assert ticket.needs_fix!(code.id)
end

Given /^"([^"]*)" takes code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  assert ticket.take!
end

Given /^"([^"]*)" commits code ticket (\d+) in "([^"]*)"$/ do |login, number, revision|
  ticket = CodeTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  ticket.commit!(revision)
end

Given /^"([^"]*)" stages code ticket (\d+) in "([^"]*)"$/ do |login, number, revision|
  ticket = CodeTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  ticket.commit!("1")
  ticket.stage!(revision)
end

Given /^"([^"]*)" verifies code ticket (\d+) in "([^"]*)"$/ do |login, number, revision|
  ticket = CodeTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  ticket.commit!("1")
  ticket.stage!("2")
  ticket.verify!(revision)
end

Given /^"([^"]*)" resolves code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  ticket.commit!("1")
  ticket.stage!("2")
  ticket.verify!("3")
  ticket.deploy!("4")
end

Given /^"([^"]*)" votes for code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  # needs a support identity which they would have gotten if they've visited the page
  User.current_user.support_identity
  assert ticket.vote!
end

Given /^"([^"]*)" comments on code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  assert ticket.comment!("foo bar")
end

Given /^"([^"]*)" watches code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  User.current_user = User.find_by_login(login)
  # needs a support identity which they would have gotten if they've visited the page
  User.current_user.support_identity
  assert ticket.watch!
end
