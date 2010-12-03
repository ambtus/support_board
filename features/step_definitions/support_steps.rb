Given /^an activated support volunteer exists with login "([^"]*)"$/ do |login|
  user = User.find_by_login(login)
  user = Factory.create(:user, :login => login) unless user
  user.activate
  user.pseuds.create(:name => "#{login} (support volunteer)", :support_volunteer => true)
end
