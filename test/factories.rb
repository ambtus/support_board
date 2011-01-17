Factory.define :user do |user|
  user.sequence(:login) { |n| "testuser#{n}" }
  user.password "secret"
  user.password_confirmation { |u| u.password }
  user.email { |u| "#{u.login}@ao3.org" }
end

Factory.define :support_ticket do |support_ticket|
  support_ticket.sequence(:id) { |n| n }
  support_ticket.sequence(:summary) { |n| "support ticket #{n}" }
  support_ticket.email { |u| "guest@ao3.org" unless u.user_id }
end

Factory.define :code_ticket do |code_ticket|
  code_ticket.sequence(:summary) { |n| "code ticket #{n}" }
end

Factory.define :faq do |faq|
  faq.sequence(:position) { |n| n }
  faq.after_build { |faq| User.current_user = Factory.create(:volunteer)}
  faq.summary { |a| "faq #{a.position}" }
end

Factory.define :volunteer, :parent => :user do |volunteer|
  volunteer.after_create { |volunteer| volunteer.support_volunteer = "1" }
end

Factory.define :support_admin, :parent => :user do |admin|
  admin.after_create { |volunteer| volunteer.support_admin = "1" }
end

Factory.define :release_note do |note|
  note.sequence(:release) { |n| n }
end

Factory.define :code_commit do |commit|
  commit.sequence(:author) { |n| "committer#{n}" }
end
