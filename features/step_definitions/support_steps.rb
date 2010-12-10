Given /^an activated support volunteer exists with login "([^"]*)"$/ do |login|
  # " reset quotes for color
  user = User.find_by_login(login)
  unless user
    user = Factory.create(:user, :login => login)
    user.activate
    user.support_volunteer = '1'
    user.pseuds.create(:name => "#{login}(SV)", :support_volunteer => true)
  end
end

Given /the following activated support volunteers? exists?/ do |table|
  table.hashes.each do |hash|
    user = Factory.create(:user, hash)
    user.activate
    user.support_volunteer = '1'
    user.pseuds.create(:name => "#{user.login}(SV)", :support_volunteer => true)
  end
end

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

Given /^"([^"]*)" has a support pseud "([^"]*)"$/ do |login, name|
  user = User.find_by_login(login)
  assert user.support_volunteer
  Factory.create(:pseud, :user_id => user.id, :name => name, :support_volunteer => true)
end

# user actions on tickets

Given /^a user responds to support ticket (\d+)$/ do |number|
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login("someone")
  user = Factory.create(:user, :login => "someone") unless user
  user.activate
  ticket.support_details.build(:pseud => user.default_pseud, :content => "blah blah")
  ticket.save
  ticket.send_update_notifications
end

Given /^a support volunteer responds to support ticket (\d+)$/ do |number|
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login("somevolunteer")
  unless user
    user = Factory.create(:user, :login => "somevolunteer")
    user.activate
    user.support_volunteer = '1'
    user.default_pseud.update_attribute(:support_volunteer, true)
  end
  ticket.support_details.build(:pseud => user.support_pseud, :support_response => true, :content => "foo bar")
  ticket.save
  ticket.send_update_notifications
end

Given /^"([^"]*)" responds to support ticket (\d+)$/ do |login, number|
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
  ticket.support_notifications.create(:email => user.email, :public_watcher => true)
end

Given /^"([^"]*)" accepts a response to support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
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
  assert user.support_volunteer
  ticket.pseud = user.support_pseud
  ticket.save
  ticket.send_update_notifications
end

Given /^"([^"]*)" categorizes support ticket (\d+) as Comment$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  assert user.support_volunteer
  ticket.mark_as_comment!(user.support_pseud)
end

Given /^a support volunteer responds to code ticket (\d+)$/ do |number|
  ticket = CodeTicket.all[number.to_i - 1]
  user = Factory.create(:user)
  user.activate
  user.support_volunteer = '1'
  user.pseuds.create(:support_volunteer => true, :name => "foo")
  ticket.code_details.build(:pseud => user.support_pseud, :support_response => true, :content => "foo bar")
  ticket.save
  ticket.send_update_notifications
end

Given /^"([^"]*)" takes code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  assert user.support_volunteer
  ticket.send_steal_notification(user.support_pseud) if ticket.pseud_id
  ticket.update_attribute(:pseud_id, user.support_pseud.id)
end

# TODO - replace this with one of the resolution methods to be determined
Given /^"([^"]*)" resolves code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.all[number.to_i - 1]
  user = User.find_by_login(login)
  assert user.support_volunteer
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
  ticket.code_notifications.create(:email => user.email)
end

Given /^an activated support admin exists with login "([^"]*)"$/ do |login|
  # " reset quotes for color
  user = User.find_by_login(login)
  unless user
    user = Factory.create(:user, :login => login)
    user.activate
    user.support_admin = '1'
    user.pseuds.create(:name => "#{login}(SV)", :support_volunteer => true)
  end
end

Given /^I am logged in as support admin "([^"]*)"$/ do |login|
  # " reset quotes for color
  visit logout_path
  Given %{an activated support admin exists with login "#{login}"}
  visit root_path
  fill_in "User name", :with => login
  fill_in "Password", :with => "secret"
  check "Remember me"
  click_button "Log in"
  assert UserSession.find
end
