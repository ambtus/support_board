Given /^an activated support volunteer exists with login "([^"]*)"$/ do |login|
  user = User.find_by_login(login)
  user = Factory.create(:user, :login => login) unless user
  user.activate
  user.pseuds.create(:name => "#{login} (support volunteer)", :support_volunteer => true)
end

# do this all behind the scenes, so as not to interfere with the users session
When /^a support volunteer responds to support ticket (\d+)$/ do |number|
  ticket = SupportTicket.all[number.to_i - 1]
  user = Factory.create(:user)
  user.activate
  user.support_volunteer = '1'
  user.pseuds.create(:support_volunteer => true, :name => "foo")
  ticket.support_details.create!(:pseud => user.support_pseud, :support_response => true, :content => "blah blah")
  SupportMailer.update_notification(ticket).deliver if ticket.support_watchers.count > 0
end

When /^a user responds to support ticket (\d+)$/ do |number|
  ticket = SupportTicket.all[number.to_i - 1]
  user = Factory.create(:user)
  user.activate
  ticket.support_details.create!(:pseud => user.default_pseud, :content => "blah blah")
  SupportMailer.update_notification(ticket).deliver if ticket.support_watchers.count > 0
end

