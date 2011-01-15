# demo seed data.
#  load by running
#  rails runner db/demo_seeds.rb
# Also used for features:
#  load and then dump to fixtures, create roles_users.yml by hand

# users
newbie = User.create!(:login => "newbie", :email => "newbie@ao3.org",
  :password => "secret", :password_confirmation => "secret")

dean = User.create!(:login => "dean", :email => "dean@ao3.org",
  :password => "secret", :password_confirmation => "secret")
john = User.create!(:login => "john", :email => "john@ao3.org",
  :password => "secret", :password_confirmation => "secret")
jim = User.create!(:login => "jim", :email => "jim@ao3.org",
  :password => "secret", :password_confirmation => "secret")

# support volunteers
sam = User.create!(:login => "sam", :email => "sam@ao3.org",
  :password => "secret", :password_confirmation => "secret")
sam.support_volunteer = "1"
rodney = User.create!(:login => "rodney", :email => "rodney@ao3.org",
  :password => "secret", :password_confirmation => "secret")
rodney.support_volunteer = "1"
blair = User.create!(:login => "blair", :email => "blair@ao3.org",
  :password => "secret", :password_confirmation => "secret")
blair.support_volunteer = "1"

# support admin
rodney.support_admin = "1"
bofh = User.create!(:login => "bofh", :email => "bofh@ao3.org",
  :password => "secret", :password_confirmation => "secret")
bofh.support_admin = "1"

# code tickets
ct1 = CodeTicket.create!(:summary => "fix the roof")
User.current_user = sam
ct1.vote!

ct2 = CodeTicket.create!(:summary => "save the world")
User.current_user = sam
ct2.take!
CodeCommit.create!(:author => "sam", :message => "no issue number", :pushed_at => Time.now)
User.current_user = dean
ct2.vote!
User.current_user = rodney
ct2.vote!
User.current_user = jim
ct2.vote!

ct3 = CodeTicket.create!(:summary => "repeal DADA")
User.current_user = rodney
ct3.take!
CodeCommit.create!(:author => "rodney", :message => "closes issue 3", :pushed_at => Time.now)
ct3.reload.stage!
User.current_user = bofh
ct3.verify!
User.current_user = rodney
ct3.vote!
User.current_user = john
ct3.vote!
User.current_user = jim
ct3.vote!

ct4 = CodeTicket.create!(:summary => "build a zpm")
User.current_user = john
ct4.comment!("haven't you started this yet?")
User.current_user = rodney
ct4.take!
CodeCommit.create!(:author => "rodney", :message => "issue 4", :pushed_at => Time.now)
User.current_user = blair
ct4.reload.stage!

ct5 = CodeTicket.create!(:summary => "find a sentinel")
User.current_user = jim
ct5.comment!("what's a sentinel?")
User.current_user = blair
ct5.take!
CodeCommit.create!(:author => "blair", :message => "fixed issue 5", :pushed_at => Time.now)

ct6 = CodeTicket.create!(:summary => "create the world wide web")
User.current_user = bofh
ct6.vote!
ct6.take!
CodeCommit.create!(:author => "bofh", :message => "issue 6", :pushed_at => Time.now)
ct6.reload.stage!
User.current_user = rodney
ct6.verify!
rn = ReleaseNote.create!(:release => "1.0", :content => "new in this release, the www!")
ct6.deploy!(rn.id)
rn.update_attribute(:posted, true)
rn = ReleaseNote.create!(:release => "2.0", :content => "new in this release, web 2.0!")

# faqs
User.current_user = sam
faq1 = Faq.create!(:title => "where to find salt")
User.current_user = bofh
faq1.post!

User.current_user = rodney
faq2 = Faq.create!(:title => "why we don't have enough ZPMs")

User.current_user = rodney
faq3 =Faq.create!(:title => "what's DADA?")
faq3.post!
User.current_user = nil
faq3.vote!

User.current_user = bofh
faq4 = Faq.create!(:title => "how to recover your password")
faq4.post!
User.current_user = nil
faq4.vote!
faq4.vote!
faq4.vote!


User.current_user = blair
faq5 = Faq.create!(:title => "what's a sentinel?")

# support tickets
st1 = SupportTicket.create!(:summary => "some problem", :email => "guest@ao3.org", :authenticity_token => "123456", :user_agent => "Mozilla/5.0", :ip_address => "72.14.204.103")

st2 = SupportTicket.create!(:summary => "a personal problem", :email => "guest@ao3.org", :private => true)
User.current_user = sam
st2.spam!

st3 = SupportTicket.create!(:summary => "where's the salt?", :user_id => dean.id, :anonymous => false)
User.current_user = dean
st3.comment!("and the holy water")
User.current_user = sam
st3.take!

st4 = SupportTicket.create!(:summary => "repeal DADA", :user_id => john.id, :private =>true, :url => "/faqs/3")
User.current_user = rodney
st4.needs_fix!(ct3.id)

st5 = SupportTicket.create!(:summary => "what's my password?", :user_id => john.id, :private =>true, :anonymous => false)
st5.answer!(faq4.id)
User.current_user = john
faq4.vote!

st6 = SupportTicket.create!(:summary => "what's wrong with me?", :user_id => jim.id, :private =>true)
User.current_user = blair
st6.answer!(faq5.id)

st7 = SupportTicket.create!(:summary => "where can I find a guide", :user_id => jim.id)
User.current_user = blair
st7.needs_fix!(ct5.id)

st8 = SupportTicket.create!(:summary => "where are you, dean?", :user_id => sam.id, :url => "/users/dean")
User.current_user = sam
st8.comment!("don't make me come looking for you!", false)

st9 = SupportTicket.create!(:summary => "where are you, castiel?", :user_id => dean.id)
User.current_user = bofh
st9.take!

User.current_user = blair
st10 = SupportTicket.create!(:summary => "You guys rock!", :email => "happy@ao3.org")
st10.post!

st11 = SupportTicket.create!(:summary => "thanks for fixing it", :email => "happy@ao3.org", :private => true)
st11.post!

st12 = SupportTicket.create!(:summary => "you guys suck!", :user_id => newbie.id)
st12.post!

User.current_user = rodney
st13 = SupportTicket.create!(:summary => "I like the archive", :user_id => john.id, :private => true)
st13.post!

st14 = SupportTicket.create!(:summary => "I'm leaving fandom forever!", :user_id => dean.id, :anonymous => false)
st14.post!

st15 = SupportTicket.create!(:summary => "thank you for helping", :user_id => jim.id, :private => true, :anonymous => false)
User.current_user = sam
st15.post!

st16 = SupportTicket.create!(:summary => "embarassing rash", :user_id => jim.id, :private => true)
