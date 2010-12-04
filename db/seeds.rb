# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
User.create!(:login => "dean", :email => "dean@ao3.org",
  :password => "secret", :password_confirmation => "secret")
sam = User.create!(:login => "sam", :email => "sam@ao3.org",
  :password => "secret", :password_confirmation => "secret")
sam.support_volunteer = "1"
sam.pseuds.create(:name => "sammy", :support_volunteer => true)
