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
  user.support_identity.update_attribute(:name, name)
end

# user actions on tickets

Given /^a user responds to support ticket (\d+)$/ do |number|
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login("someone")
  user = Factory.create(:user, :login => "someone") unless user
  ticket.support_details.build(:support_identity => user.support_identity, :content => "blah blah")
  ticket.save
  ticket.send_update_notifications
end

# generic volunteer actions on tickets

Given /^a volunteer responds to support ticket (\d+)$/ do |number|
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login("oracle") ||
  unless user
    Given %{a volunteer exists with login: "oracle"}
    user = User.find_by_login("oracle")
  end
  assert user.support_volunteer?
  ticket.support_details.build(:support_identity => user.support_identity, :support_response => true, :content => "foo bar")
  ticket.save
  ticket.send_update_notifications
end

When /^a volunteer creates a faq from support ticket (\d+)$/ do |number|
  ticket = SupportTicket.all[number.to_i - 1]
  Given %{a volunteer exists with login: "oracle"}
  user = User.find_by_login("oracle")
  faq = Factory.create(:faq)
  ticket.update_attribute(:faq_id, faq.id)
  ticket.update_attribute(:support_identity_id, user.support_identity_id)
  ticket.send_update_notifications
end

When /^a volunteer links support ticket (\d+) to faq (\d+)$/ do |arg1, arg2|
  ticket = SupportTicket.all[arg1.to_i - 1]
  faq = Faq.find_by_position(arg2.to_i)
  Given %{a volunteer exists with login: "oracle"}
  user = User.find_by_login("oracle")
  ticket.update_attribute(:faq_id, faq.id)
  ticket.update_attribute(:support_identity_id, user.support_identity_id)
  ticket.send_update_notifications
end

Given /^a volunteer responds to code ticket (\d+)$/ do |number|
  ticket = CodeTicket.all[number.to_i - 1]
  Given %{a volunteer exists with login: "oracle"}
  user = User.find_by_login("oracle")
  ticket.code_details.build(:support_identity => user.support_identity, :support_response => true, :content => "foo bar")
  ticket.save
  ticket.send_update_notifications
end

# named user actions on tickets.
# create the support identity they'd get working through the web interface

Given /^"([^"]*)" responds to support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  assert user = User.find_by_login(login)
  user.support_identity
  ticket.support_details.build(:support_identity => user.support_identity, :content => "blah blah")
  ticket.save
  ticket.send_update_notifications
end

Given /^"([^"]*)" watches support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  assert user = User.find_by_login(login)
  user.support_identity
  ticket.support_notifications.create(:email => user.email, :public_watcher => true)
end

Given /^"([^"]*)" accepts a response to support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  user.support_identity
  assert ticket.user == user
  response = ticket.support_details.where(:resolved_ticket => false).first
  ticket.support_details_attributes = {"0"=>{"resolved_ticket"=>"1", "id"=>response.id}}
  ticket.save
  ticket.send_update_notifications
end

Given /^"([^"]*)" takes support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  assert user.support_volunteer?
  ticket.support_identity_id = user.support_identity_id
  ticket.save
  ticket.send_update_notifications
end

Given /^"([^"]*)" categorizes support ticket (\d+) as Comment$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  assert user.support_volunteer?
  ticket.mark_as_comment!(user.support_identity)
end

Given /^"([^"]*)" takes code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  assert user.support_volunteer?
  ticket.send_steal_notification(user.support_identity) if ticket.support_identity_id
  ticket.update_attribute(:support_identity_id, user.support_identity_id)
end

Given /^"([^"]*)" resolves code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  assert user.support_volunteer?
  ticket.support_identity_id = user.support_identity_id
  ticket.committed_rev = "12345"
  ticket.save
  ticket.send_update_notifications
end

Given /^"([^"]*)" votes up code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  assert user = User.find_by_login(login)
  user.support_identity
  ticket.code_votes.create(:user_id => user.id, :vote => 1)
end

Given /^"([^"]*)" comments on code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  assert user = User.find_by_login(login)
  ticket.code_details.build(:support_identity => user.support_identity, :content => "blah blah", :support_response => user.support_volunteer?)
  ticket.save
  ticket.send_update_notifications
end

Given /^"([^"]*)" watches code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  assert user = User.find_by_login(login)
  user.support_identity
  ticket.code_notifications.create(:email => user.email)
end

