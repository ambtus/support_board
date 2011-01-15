Given /^"([^"]*)" comments on support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  assert ticket.comment!("foo bar")
end

Given /^"([^"]*)" watches support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  assert ticket.watch!
end

Given /^"([^"]*)" accepts a comment on support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  detail = ticket.support_details.where(:resolved_ticket => false).first
  assert ticket.accept!(detail.id)
end

Given /^"([^"]*)" takes support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  assert ticket.take!
end

Given /^"([^"]*)" posts support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  assert ticket.post!
end

When /^"([^"]*)" creates a faq from support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  assert faq = ticket.answer!
  faq.update_attribute(:title, "new faq")
end

When /^"([^"]*)" creates a faq from the last support ticket$/ do |login|
  # " reset quotes for color
  ticket = SupportTicket.last
  User.current_user = User.find_by_login(login)
  assert faq = ticket.answer!
  faq.update_attribute(:title, "new faq")
end

When /^"([^"]*)" links support ticket (\d+) to faq (\d+)$/ do |login, arg1, arg2|
  # " reset quotes for color
  ticket = SupportTicket.find(arg1.to_i)
  assert faq = Faq.find(arg2.to_i)
  User.current_user = User.find_by_login(login)
  assert ticket.answer!(faq.id)
end

When /^"([^"]*)" links the last support ticket to faq (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.last
  assert faq = Faq.find(number.to_i)
  User.current_user = User.find_by_login(login)
  assert ticket.answer!(faq.id)
end

When /^"([^"]*)" creates a code ticket from support ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = SupportTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  assert ticket.needs_fix!
end

When /^"([^"]*)" links support ticket (\d+) to code ticket (\d+)$/ do |login, arg1, arg2|
  # " reset quotes for color
  ticket = SupportTicket.find(arg1.to_i)
  assert code = CodeTicket.find(arg2.to_i)
  User.current_user = User.find_by_login(login)
  assert ticket.needs_fix!(code.id)
end

Given /^"([^"]*)" takes code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  assert ticket.take!
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
  assert ticket.vote!
end

Given /^"([^"]*)" comments on code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  assert ticket.comment!("foo bar")
end

Given /^"([^"]*)" watches code ticket (\d+)$/ do |login, number|
  # " reset quotes for color
  ticket = CodeTicket.find(number.to_i)
  User.current_user = User.find_by_login(login)
  assert ticket.watch!
end
