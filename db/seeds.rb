# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# users
dean = User.create(:login => "dean", :email => "dean@ao3.org",
  :password => "secret", :password_confirmation => "secret")
dean.support_identity
john = User.create(:login => "john", :email => "john@ao3.org",
  :password => "secret", :password_confirmation => "secret")
john.support_identity
jim = User.create(:login => "jim", :email => "jim@ao3.org",
  :password => "secret", :password_confirmation => "secret")
jim.support_identity

# support volunteers
sam = User.create(:login => "sam", :email => "sam@ao3.org",
  :password => "secret", :password_confirmation => "secret")
sam.support_volunteer = "1"
rodney = User.create(:login => "rodney", :email => "rodney@ao3.org",
  :password => "secret", :password_confirmation => "secret")
rodney.support_volunteer = "1"
blair = User.create(:login => "blair", :email => "blair@ao3.org",
  :password => "secret", :password_confirmation => "secret")
blair.support_volunteer = "1"

# support admin
rodney.support_admin = "1"
bofh = User.create(:login => "bofh", :email => "bofh@ao3.org",
  :password => "secret", :password_confirmation => "secret")
bofh.support_admin = "1"

# code tickets
ct1 = CodeTicket.create(:summary => "fix the roof")

ct2 = CodeTicket.create(:summary => "save the world")
User.current_user = sam
ct2.take!

ct3 = CodeTicket.create(:summary => "repeal DADA")
User.current_user = rodney
ct3.take!
ct3.commit!("2010")

ct4 = CodeTicket.create(:summary => "build a zpm")
User.current_user = rodney
ct4.take!
ct4.commit!("2009")
ct4.stage!("2010")

ct5 = CodeTicket.create(:summary => "find a sentinel")
User.current_user = blair
ct5.take!
ct5.commit!("1983")
ct5.stage!("1996")
ct5.verify!("1996")

ct6 = CodeTicket.create(:summary => "create the world wide web")
User.current_user = bofh
ct6.take!
ct6.commit!("1980")
ct6.stage!("1990")
ct6.verify!("2000")
ct6.deploy!("2010")

# faqs
User.current_user = sam
faq1 = Faq.create(:title => "where to find salt")
User.current_user = bofh
faq1.post!

User.current_user = rodney
faq2 = Faq.create(:title => "why we don't have enough ZPMs")

User.current_user = rodney
faq3 =Faq.create(:title => "what's DADA?")
faq2.post!

User.current_user = bofh
faq4 = Faq.create(:title => "how to recover your password")
faq4.post!

User.current_user = blair
faq5 = Faq.create(:title => "what's a sentinel?")

# support tickets
st1 = SupportTicket.create(:summary => "some problem", :email => "guest@ao3.org")

st2 = SupportTicket.create(:summary => "a personal problem", :email => "guest@ao3.org", :private => true)
User.current_user = sam
st2.spam!

st3 = SupportTicket.create(:summary => "where's the salt?", :user_id => dean.id)
st3.take!

st4 = SupportTicket.create(:summary => "repeal DADA", :user_id => john.id, :private =>true)
User.current_user = rodney
st4.needs_fix!(ct3.id)

st5 = SupportTicket.create(:summary => "what's my password?", :user_id => john.id, :private =>true, :display_user_name => true)
st5.answer!(faq4.id)

st6 = SupportTicket.create(:summary => "what's wrong with me?", :user_id => jim.id, :private =>true)
User.current_user = blair
st6.answer!(faq5.id)

