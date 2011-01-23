Given /^"([^"]*)" comments on support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  ticket.user_comment!("foo bar")
end

Given /^"([^"]*)" watches support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  ticket.watch!
end

Given /^"([^"]*)" accepts a comment on support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  detail = ticket.support_details.where(:resolved_ticket => false).first
  ticket.accept!(detail.id)
end

Given /^"([^"]*)" takes support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  ticket.take!
end

Given /^"([^"]*)" posts support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  ticket.post!
end

Given /^"([^"]*)" posts faq (\d+)$/ do |login, number|
  # " reset quotes for color
  faq = Faq.find(number.to_i)
  User.current_user = User.find_by_login(login)
  faq.post!
end

Given /^"([^"]*)" posts the last faq$/ do |login|
  # " reset quotes for color
  faq = Faq.last
  User.current_user = User.find_by_login(login)
  faq.post!
end

When /^"([^"]*)" creates a faq from support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  faq = Faq.create!(:summary => "new faq", :content => "something interesting")
  ticket.answer!(faq.id)
end

When /^"([^"]*)" creates a faq from the last support ticket$/ do |login|
  # " reset quotes for color
  ticket = SupportTicket.last
  User.current_user = User.find_by_login(login)
  faq = Faq.create!(:summary => "new faq", :content => "something interesting")
  ticket.answer!(faq.id)
end

When /^"([^"]*)" links support ticket (\d+) to faq (\d+)$/ do |login, arg1, arg2|
  # " reset quotes for color
  ticket = SupportTicket.find(arg1.to_i)
  assert faq = Faq.find(arg2.to_i)
  User.current_user = User.find_by_login(login)
  ticket.answer!(faq.id)
end

When /^"([^"]*)" links the last support ticket to faq (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.last
  assert faq = Faq.find(number.to_i)
  User.current_user = User.find_by_login(login)
  ticket.answer!(faq.id)
end

When /^"([^"]*)" creates a code ticket from support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  ticket.needs_fix!
end

When /^"([^"]*)" links support ticket (\d+) to code ticket (\d+)$/ do |login, arg1, arg2|
  # " reset quotes for color
  ticket = SupportTicket.find(arg1.to_i)
  assert code = CodeTicket.find(arg2.to_i)
  User.current_user = User.find_by_login(login)
  ticket.needs_fix!(code.id)
end

Given /^"([^"]*)" takes code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  ticket.take!
end

Given /^"([^"]*)" commits code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  cc = CodeCommit.create(:author => login)
  ticket.commit!(cc.id)
end

Given /^"([^"]*)" stages code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  ticket.stage!
end

Given /^"([^"]*)" verifies code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  ticket.verify!
end

Given /^"([^"]*)" deploys code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  ticket.deploy!(Factory.first.id)
end

Given /^"([^"]*)" votes for code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  ticket.vote!
end

Given /^"([^"]*)" comments on code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  ticket.comment!("foo bar")
end

Given /^"([^"]*)" watches code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  ticket.watch!
end
