Factory.define :admin do |f|
  f.sequence(:login) { |n| "admin-#{n}" }
  f.password "secret"
  f.password_confirmation { |a| a.password }
  f.sequence(:email) { |n| "foo#{n}@ao3.org" }
end

Factory.define :user do |f|
  f.sequence(:login) { |n| "testuser#{n}" }
  f.password "secret"
  f.password_confirmation { |u| u.password }
  f.sequence(:email) { |n| "foo#{n}@ao3.org" }
end

Factory.define :pseud do |f|
  f.name "my test pseud"
  f.association :user
end
