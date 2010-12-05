Given /^I am logged in as support volunteer "([^"]*)"$/ do |login|
  # " reset quotes for color
  visit logout_path
  Given %{an activated support volunteer exists with login "#{login}"}
  visit root_path
  fill_in "User name", :with => login
  fill_in "Password", :with => "secret"
  check "Remember me"
  click_button "Log in"
  assert UserSession.find
end

Given /^an activated support volunteer exists with login "([^"]*)"$/ do |login|
  # " reset quotes for color
  user = User.find_by_login(login)
  user = Factory.create(:user, :login => login) unless user
  user.activate
  user.support_volunteer = '1'
  user.pseuds.create(:name => "#{login}(SV)", :support_volunteer => true)
  assert user.is_support_volunteer?
  assert user.support_pseud
end

Given /the following activated support volunteers? exists?/ do |table|
  table.hashes.each do |hash|
    user = Factory.create(:user, hash)
    user.activate
    user.support_volunteer = '1'
    user.pseuds.create(:name => "#{user.login}(SV)", :support_volunteer => true)
  end
end

When /^a support volunteer responds to support ticket (\d+)$/ do |number|
  ticket = SupportTicket.all[number.to_i - 1]
  user = Factory.create(:user)
  user.activate
  user.support_volunteer = '1'
  user.pseuds.create(:support_volunteer => true, :name => "#{user.login}(SV)")
  ticket.support_details.build(:pseud => user.support_pseud, :support_response => true, :content => "foo bar")
  ticket.save
  ticket.send_update_notifications
end

When /^a support volunteer responds to code ticket (\d+)$/ do |number|
  ticket = CodeTicket.all[number.to_i - 1]
  user = Factory.create(:user)
  user.activate
  user.support_volunteer = '1'
  user.pseuds.create(:support_volunteer => true, :name => "foo")
  ticket.code_details.build(:pseud => user.support_pseud, :support_response => true, :content => "foo bar")
  ticket.save
  ticket.send_update_notifications
end

When /^a user responds to support ticket (\d+)$/ do |number|
  ticket = SupportTicket.all[number.to_i - 1]
  user = Factory.create(:user)
  user.activate
  ticket.support_details.build(:pseud => user.default_pseud, :content => "blah blah")
  ticket.save
  ticket.send_update_notifications
end

When /^"([^"]*)" responds to support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  ticket.support_details.build(:pseud => user.default_pseud, :content => "blah blah")
  ticket.save
  ticket.send_update_notifications
end

Given /^"([^"]*)" watches support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  ticket.support_watchers.create(:email => user.email, :public_watcher => true)
end

# this method doesn't send notifications so don't expect it to
Given /^"([^"]*)" accepts a response to support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  assert ticket.user == user
  response = ticket.support_details.where(:resolved_ticket => false).first
  response.update_attribute(:resolved_ticket, true)
end

Given /^"([^"]*)" takes support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  assert user.is_support_volunteer?
  ticket.pseud = user.support_pseud
  ticket.save
  ticket.send_update_notifications
end


Given /^"([^"]*)" takes code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  assert user.is_support_volunteer?
  ticket.pseud = user.support_pseud
  ticket.save
  ticket.send_update_notifications
end

Given /^"([^"]*)" resolves code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  assert ticket.pseud == user.support_pseud
  ticket.resolved = true
  ticket.save
  ticket.send_update_notifications
end

Given /^"([^"]*)" votes up code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  ticket.code_votes.create(:user_id => user.id, :vote => 1)
end

Given /^"([^"]*)" comments on code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  ticket.code_details.build(:pseud => user.default_pseud, :content => "blah blah")
  ticket.save
  ticket.send_update_notifications
end

Given /^"([^"]*)" watches code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  ticket.code_watchers.create(:email => user.email)
end

