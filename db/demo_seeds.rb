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
CodeCommit.create!(:author => "sam", :message => "this should fix it", :pushed_at => Date.today)
User.current_user = dean
ct2.vote!
User.current_user = rodney
ct2.vote!
User.current_user = jim
ct2.vote!
User.current_user = bofh
ct2.vote!

ct3 = CodeTicket.create!(:summary => "repeal DADT")
User.current_user = rodney
ct3.take!
CodeCommit.create!(:author => "rodney", :message => "finally closes issue 3", :pushed_at => Date.today)
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
User.current_user = bofh
ct4.comment!("rodney, get the lead out!", true, true)
CodeCommit.create!(:author => "rodney", :message => "issue 4. run db:migrate afterwards.", :pushed_at => Date.today)
User.current_user = rodney
ct4.comment!("happy now, master?", true, true)
User.current_user = blair
ct4.comment!("geeze guys, i don't want to know about your kinks", true, true)
ct4.reload.stage!

ct5 = CodeTicket.create!(:summary => "find a sentinel")
User.current_user = jim
ct5.comment!("what's a sentinel?")
User.current_user = blair
ct5.take!
CodeCommit.create!(:author => "blair", :message => "related to issue 5", :pushed_at => Date.today)

ct6 = CodeTicket.create!(:summary => "create the world wide web")
User.current_user = bofh
ct6.vote!
ct6.take!
CodeCommit.create!(:author => "bofh", :message => "issue 6", :pushed_at => Date.today)
ct6.reload.stage!
User.current_user = rodney
ct6.verify!
rn = ReleaseNote.create!(:release => "1.0", :content => "new in this release, the www!")
ct6.deploy!(rn.id)
rn.update_attribute(:posted, true)
rn = ReleaseNote.create!(:release => "2.0", :content => "new in this release, web 2.0!")

# faqs
User.current_user = sam
faq1 = Faq.create!(:summary => "where to find salt", :content => "in the sea. or the great salt lake. possibly your salt shaker")
User.current_user = bofh
faq1.post!

User.current_user = rodney
faq2 = Faq.create!(:summary => "why we don't have enough ZPMs", :content => "this should be self evident")
faq2.comment!("why do i have to write this?", true, nil, true)
User.current_user = blair
faq2.comment!("because nobody else can", true, nil, true)

User.current_user = rodney
faq3 =Faq.create!(:summary => "what's DADT?", :content => "Ask me no questions and I'll tell you no lies")
faq3.post!
User.current_user = nil
faq3.vote!

User.current_user = bofh
faq4 = Faq.create!(:summary => "how to recover your password", :content => "visit the lost password page")
User.current_user = bofh
faq4.comment!("hack the database ;)", true, nil, true)
faq4.post!
User.current_user = nil
faq4.vote!
faq4.vote!
faq4.vote!

User.current_user = blair
faq5 = Faq.create!(:summary => "what's a sentinel?", :content => "lookout: a person employed to keep watch for some anticipated event")

# support tickets
st1 = SupportTicket.create!(
  :summary => "some problem",
  :email => "guest@ao3.org",
  :url => "/",
  :authenticity_token => "123456",
  :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.638.0 Safari/534.16",
  :ip_address => "72.14.204.103"
)

st2 = SupportTicket.create!(
  :summary => "a personal problem",
  :email => "guest@ao3.org",
  :private => true,
  :url => "/faqs",
  :authenticity_token => "123456",
  :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.638.0 Safari/534.16",
  :ip_address => "72.14.204.103"
)
User.current_user = sam
st2.comment!("a personal problem, my ass", true, nil, true)
st2.spam!
User.current_user = rodney
st2.comment!("your ass is not my problem", true, nil, true)
User.current_user = bofh
st2.comment!("cut it out, guys", true, nil, true)

st3 = SupportTicket.create!(
  :summary => "where's the salt?",
  :user_id => dean.id,
  :anonymous => false,
  :url => "/bookmarks",
  :authenticity_token => "666555",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "71.111.1.40"
)
User.current_user = dean
st3.comment!("and the holy water")
User.current_user = sam
st3.take!

st4 = SupportTicket.create!(
  :summary => "repeal DADT",
  :user_id => john.id,
  :private =>true,
  :url => "/faqs/3",
  :authenticity_token => "756756",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_5; de-de) AppleWebKit/534.15+ (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4",
  :ip_address => "98.223.153.124"
)
User.current_user = rodney
st4.needs_fix!(ct3.id)

st5 = SupportTicket.create!(
  :summary => "what's my password?",
  :user_id => john.id,
  :private =>true,
  :anonymous => false,
  :url => "/users/john",
  :authenticity_token => "756756",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_5; de-de) AppleWebKit/534.15+ (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4",
  :ip_address => "98.223.153.124"
)
st5.answer!(faq4.id)
User.current_user = john
faq4.vote!

st6 = SupportTicket.create!(
  :summary => "what's wrong with me?",
  :user_id => jim.id,
  :private =>true,
  :url => "/users/jim/pseuds",
  :authenticity_token => "8889662",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; nb-NO; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13",
  :ip_address => "24.223.182.51"
)
User.current_user = blair
st6.answer!(faq5.id)

st7 = SupportTicket.create!(
  :summary => "where can I find a guide",
  :user_id => jim.id,
  :url => "/faqs/5",
  :authenticity_token => "8889662",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; nb-NO; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13",
  :ip_address => "24.223.182.51"
)
User.current_user = blair
st7.needs_fix!(ct5.id)

st8 = SupportTicket.create!(
  :summary => "where are you, dean?",
  :user_id => sam.id,
  :url => "/users/dean",
  :authenticity_token => "22333566",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "71.111.1.40"
)
User.current_user = sam
st8.comment!("don't make me come looking for you!", false)

st9 = SupportTicket.create!(
  :summary => "where are you, castiel?",
  :user_id => dean.id,
  :url => "/users/castiel",
  :authenticity_token => "666555",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "71.111.1.40"
)
User.current_user = bofh
st9.take!

User.current_user = blair
st10 = SupportTicket.create!(
  :summary => "You guys rock!",
  :email => "happy@ao3.org",
  :url => "/works/666",
  :authenticity_token => "44400661",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "24.98.14.241"
)
st10.post!

st11 = SupportTicket.create!(
  :summary => "thanks for fixing it",
  :email => "happy@ao3.org",
  :url => "/tags",
  :private => true,
  :authenticity_token => "44400661",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "24.98.14.241"
)
st11.post!

st12 = SupportTicket.create!(
  :summary => "you guys suck!",
  :user_id => newbie.id,
  :url => "/users/newbie/preferences",
  :authenticity_token => "1777335002",
  :user_agent => "BlackBerry9330/5.0.0.857 Profile/MIDP-2.1 Configuration/CLDC-1.1 VendorID/105",
  :ip_address => "98.1.153.77"
)
st12.post!

User.current_user = rodney
st13 = SupportTicket.create!(
  :summary => "I like the archive",
  :user_id => john.id,
  :private => true,
  :url => "/tags/Calvin%20*a*%20Hobbes/works/",
  :authenticity_token => "756756",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_5; de-de) AppleWebKit/534.15+ (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4",
  :ip_address => "98.223.153.124"
)
st13.post!

st14 = SupportTicket.create!(
  :summary => "I'm leaving fandom forever!",
  :user_id => dean.id,
  :anonymous => false,
  :url => "/collections/yuletidemadness2010/",
  :authenticity_token => "666555",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "71.111.1.40"
)
User.current_user = sam
st14.comment!("small loss", true, nil, true)
st14.post!

st15 = SupportTicket.create!(
  :summary => "thank you for helping",
  :user_id => jim.id,
  :private => true,
  :anonymous => false,
  :url => "/support_tickets/6",
  :authenticity_token => "8889662",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; nb-NO; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13",
  :ip_address => "24.223.182.51"
)
User.current_user = sam
st15.post!

st16 = SupportTicket.create!(
  :summary => "embarassing rash",
  :user_id => jim.id,
  :private => true,
  :url => "/faqs/5",
  :authenticity_token => "8889662",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; nb-NO; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13",
  :ip_address => "24.223.182.51"
)
User.current_user = blair
st16.comment!("i bet this is jim", true, nil, true)
User.current_user = sam
st16.comment!("nah, must be dean", true, nil, true)
User.current_user = rodney
st16.comment!("better not be john", true, nil, true)
User.current_user = bofh
st16.comment!("stop gossiping about the lusers and get back to work", true, nil, true)

st17 = SupportTicket.create!(
  :summary => "my account was hacked",
  :email => "happy@ao3.org",
  :private => true,
  :url => "/",
  :authenticity_token => "44400661",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "24.98.14.241"
)
User.current_user = blair
st17.needs_admin!

st18 = SupportTicket.create!(
  :summary => "tag pages look weird",
  :email => "guest@ao3.org",
  :url => "/tags",
  :authenticity_token => "123456",
  :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.638.0 Safari/534.16",
  :ip_address => "72.14.204.103"
)
User.current_user = sam
ct7 = st18.needs_fix!

st19 = SupportTicket.create!(
  :summary => "fanfiction.net is down",
  :email => "guest@ao3.org",
  :url => "/works/new",
  :authenticity_token => "123456",
  :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.638.0 Safari/534.16",
  :ip_address => "72.14.204.103"
)
User.current_user = bofh
st19.resolve!("not our problem")

st20 = SupportTicket.create!(
  :summary => "anon is my name",
  :user_id => john.id,
  :url => "/",
  :authenticity_token => "756756",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_5; de-de) AppleWebKit/534.15+ (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4",
  :ip_address => "98.223.153.124"
)

st21 = SupportTicket.create!(
  :summary => "please give me volunteer status",
  :user_id => dean.id,
  :anonymous => false,
  :url => "/support",
  :authenticity_token => "666555",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "71.111.1.40"
)
User.current_user = blair
st21.comment!("i thought he was leaving fandom forever", true, nil, true)
st21.needs_admin!
User.current_user = sam
st21.comment!("forever is a long time", true, nil, true)
