Factory.define :admin do |f|
  f.sequence(:login) { |n| "admin-#{n}" }
  f.password "secret"
  f.password_confirmation { |a| a.password }
  f.email { |a| "#{a.login}@ao3.org" }
end

Factory.define :user do |f|
  f.sequence(:login) { |n| "testuser#{n}" }
  f.password "secret"
  f.password_confirmation { |u| u.password }
  f.email { |u| "#{u.login}@ao3.org" }
end

Factory.define :pseud do |f|
  f.name "my test pseud"
  f.association :user
end

Factory.define :support_ticket do |f|
  f.sequence(:summary) { |n| "support ticket #{n}" }
  f.email { |u| "guest@ao3.org" unless u.user_id }
end

Factory.define :code_ticket do |f|
  f.sequence(:summary) { |n| "code ticket #{n}" }
  f.association :pseud
end
