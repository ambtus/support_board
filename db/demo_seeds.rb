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
sidra = User.create!(:login => "sidra", :email => "sidra@ao3.org",
  :password => "secret", :password_confirmation => "secret")
sidra.support_admin = "1"

# code tickets
User.current_user = sam
ct1 = CodeTicket.create!(:summary => "fix the roof")
ct1.vote!

User.current_user = sam
ct2 = CodeTicket.create!(:summary => "save the world")
ct2.take!
CodeCommit.create!(:author => "sam", :message => "this should fix it", :pushed_at => Time.now)
User.current_user = dean
ct2.vote!
User.current_user = rodney
ct2.vote!
User.current_user = jim
ct2.vote!
User.current_user = sidra
ct2.vote!

User.current_user = rodney
ct3 = CodeTicket.create!(:summary => "repeal DADT")
ct3.take!
CodeCommit.create!(:author => "rodney", :message => "finally closes issue 3", :pushed_at => Time.now)
ct3.reload.stage!
User.current_user = sidra
ct3.verify!
User.current_user = rodney
ct3.vote!
User.current_user = john
ct3.vote!
User.current_user = jim
ct3.vote!

User.current_user = rodney
ct4 = CodeTicket.create!(:summary => "build a zpm")
User.current_user = john
ct4.comment!("haven't you started this yet?")
User.current_user = rodney
ct4.take!
User.current_user = sidra
ct4.comment!("rodney, get the lead out!", "private")
CodeCommit.create!(:author => "rodney", :message => "issue 4. run db:migrate afterwards.", :pushed_at => Time.now)
User.current_user = rodney
ct4.comment!("happy now, master?", "private")
User.current_user = blair
ct4.comment!("geeze guys, i don't want to know about your kinks", "private")
User.current_user = rodney
ct4.reload.stage!

User.current_user = blair
ct5 = CodeTicket.create!(:summary => "find a sentinel")
User.current_user = jim
ct5.comment!("what's a sentinel?")
User.current_user = blair
ct5.take!
CodeCommit.create!(:author => "blair", :message => "related to issue 5", :pushed_at => Time.now)

User.current_user = sidra
ct6 = CodeTicket.create!(:summary => "create the world wide web")
ct6.comment!("should be an easy days work")
ct6.vote!
ct6.take!
CodeCommit.create!(:author => "sidra", :message => "issue 6", :pushed_at => Time.now)
ct6.reload.stage!
User.current_user = rodney
ct6.verify!
rn = ReleaseNote.create!(:release => "1.0", :content => "new in this release, the www!")
ct6.deploy!(rn.id)
rn.post!

User.current_user = sidra
rn2 = ReleaseNote.create!(:release => "2.0", :content => "new in this release, web 2.0!")
rn3 = ReleaseNote.create!(:release => "2.1", :content => "minor bug fixes")

# faqs
User.current_user = sam
faq1 = Faq.create!(:summary => "where to find salt", :content => "in the sea. or the great salt lake. possibly your salt shaker")
User.current_user = sidra
faq1.post!

User.current_user = rodney
faq2 = Faq.create!(:summary => "why we don't have enough ZPMs", :content => "this should be self evident")
faq2.comment!("why do i have to write this?", "private")
User.current_user = blair
faq2.comment!("because nobody else can", "private")

User.current_user = rodney
faq3 =Faq.create!(:summary => "what's DADT?", :content => "Ask me no questions and I'll tell you no lies")
faq3.post!
User.current_user = nil
faq3.vote!

User.current_user = sidra
faq4 = Faq.create!(:summary => "how to recover your password", :content => "visit the lost password page")
User.current_user = sidra
faq4.comment!("hack the database ;)", "private")
faq4.post!
User.current_user = nil
faq4.vote!
faq4.vote!
faq4.vote!

User.current_user = blair
faq5 = Faq.create!(:summary => "what's a sentinel?", :content => "lookout: a person employed to keep watch for some anticipated event")

# support tickets
User.current_user = nil
st1 = SupportTicket.create!(
  :summary => "some problem",
  :email => "guest@ao3.org",
  :url => "/",
  :authenticity_token => "OogoGee7oosheeciogie",
  :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.638.0 Safari/534.16",
  :ip_address => "72.14.204.103"
)

User.current_user = nil
st2 = SupportTicket.create!(
  :summary => "a personal problem",
  :email => "guest@ao3.org",
  :private => true,
  :url => "/faqs",
  :authenticity_token => "OogoGee7oosheeciogie",
  :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.638.0 Safari/534.16",
  :ip_address => "72.14.204.103"
)
User.current_user = sam
st2.user_comment!("a personal problem, my ass", "private")
st2.spam!
User.current_user = rodney
st2.user_comment!("your ass is not my problem", "private")
User.current_user = sidra
st2.user_comment!("cut it out, guys", "private")

User.current_user = dean
st3 = SupportTicket.create!(
  :summary => "where's the salt?",
  :anonymous => false,
  :url => "/bookmarks",
  :authenticity_token => "EeVei3Vahseijeangief",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "71.111.1.40"
)
User.current_user = dean
st3.user_comment!("and the holy water")
User.current_user = sam
st3.take!

User.current_user = john
st4 = SupportTicket.create!(
  :summary => "repeal DADT",
  :private =>true,
  :url => "/faqs/3",
  :authenticity_token => "UuyohjeijeezooSh5eo5",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_5; de-de) AppleWebKit/534.15+ (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4",
  :ip_address => "98.223.153.124"
)
st4.user_comment!("the sooner the better")
User.current_user = rodney
st4.needs_fix!(ct3.id)

User.current_user = john
st5 = SupportTicket.create!(
  :summary => "what's my password?",
  :private =>true,
  :anonymous => false,
  :url => "/users/john",
  :authenticity_token => "UuyohjeijeezooSh5eo5",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_5; de-de) AppleWebKit/534.15+ (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4",
  :ip_address => "98.223.153.124"
)
User.current_user = rodney
st5.answer!(faq4.id)
User.current_user = john
faq4.vote!

User.current_user = jim
st6 = SupportTicket.create!(
  :summary => "what's wrong with me?",
  :private =>true,
  :url => "/users/jim/pseuds",
  :authenticity_token => "Iyoh8eechohnei2looxu",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; nb-NO; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13",
  :ip_address => "24.223.182.51"
)
User.current_user = blair
st6.answer!(faq5.id)

User.current_user = jim
st7 = SupportTicket.create!(
  :summary => "where can I find a guide",
  :url => "/faqs/5",
  :authenticity_token => "Iyoh8eechohnei2looxu",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; nb-NO; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13",
  :ip_address => "24.223.182.51"
)
User.current_user = blair
st7.needs_fix!(ct5.id)

User.current_user = sam
st8 = SupportTicket.create!(
  :summary => "where are you, dean?",
  :anonymous => false,
  :url => "/users/dean",
  :authenticity_token => "Phoo6Teepei7rooyu5Be",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "71.111.1.40"
)
User.current_user = sam
st8.user_comment!("don't make me come looking for you!", "unofficial")

User.current_user = dean
st9 = SupportTicket.create!(
  :summary => "where are you, castiel?",
  :user_id => dean.id,
  :url => "/users/castiel",
  :authenticity_token => "EeVei3Vahseijeangief",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "71.111.1.40"
)
User.current_user = sidra
st9.take!

User.current_user = nil
st10 = SupportTicket.create!(
  :summary => "You guys rock!",
  :email => "happy@ao3.org",
  :url => "/works/666",
  :authenticity_token => "xaeDaeb6iz4iep3och5i",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "24.98.14.241"
)
User.current_user = blair
st10.post!

User.current_user = nil
st11 = SupportTicket.create!(
  :summary => "thanks for fixing it",
  :email => "happy@ao3.org",
  :url => "/tags",
  :private => true,
  :authenticity_token => "xaeDaeb6iz4iep3och5i",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "24.98.14.241"
)
User.current_user = blair
st11.post!

User.current_user = newbie
st12 = SupportTicket.create!(
  :summary => "you guys suck!",
  :url => "/users/newbie/preferences",
  :authenticity_token => "AK4Aish5Che8ohr9Eish",
  :user_agent => "BlackBerry9330/5.0.0.857 Profile/MIDP-2.1 Configuration/CLDC-1.1 VendorID/105",
  :ip_address => "98.1.153.77"
)
User.current_user = blair
st12.post!
User.current_user = sam
st12.user_comment!("and very well, too")

User.current_user = john
st13 = SupportTicket.create!(
  :summary => "I like the archive",
  :private => true,
  :url => "/tags/Calvin%20*a*%20Hobbes/works/",
  :authenticity_token => "UuyohjeijeezooSh5eo5",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_5; de-de) AppleWebKit/534.15+ (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4",
  :ip_address => "98.223.153.124"
)
User.current_user = rodney
st13.post!

User.current_user = dean
st14 = SupportTicket.create!(
  :summary => "I'm leaving fandom forever!",
  :anonymous => false,
  :url => "/collections/yuletidemadness2010/",
  :authenticity_token => "EeVei3Vahseijeangief",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "71.111.1.40"
)
User.current_user = sam
st14.user_comment!("small loss", "private")
st14.post!

User.current_user = jim
st15 = SupportTicket.create!(
  :summary => "thank you for helping",
  :private => true,
  :anonymous => false,
  :url => "/support_tickets/6",
  :authenticity_token => "Iyoh8eechohnei2looxu",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; nb-NO; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13",
  :ip_address => "24.223.182.51"
)
User.current_user = sam
st15.post!

User.current_user = jim
st16 = SupportTicket.create!(
  :summary => "embarassing rash",
  :user_id => jim.id,
  :private => true,
  :url => "/faqs/5",
  :authenticity_token => "Iyoh8eechohnei2looxu",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; nb-NO; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13",
  :ip_address => "24.223.182.51"
)
User.current_user = blair
st16.user_comment!("i bet this is jim", "private")
User.current_user = sam
st16.user_comment!("nah, must be dean", "private")
User.current_user = rodney
st16.user_comment!("better not be john", "private")
User.current_user = sidra
st16.user_comment!("stop gossiping about the lusers and get back to work", "private")

User.current_user = nil
st17 = SupportTicket.create!(
  :summary => "my account was hacked",
  :email => "happy@ao3.org",
  :private => true,
  :url => "/",
  :authenticity_token => "xaeDaeb6iz4iep3och5i",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "24.98.14.241"
)
st17.guest_owner_comment!("i think it was my ex", st17.authentication_code)
User.current_user = blair
st17.needs_admin!

User.current_user = nil
st18 = SupportTicket.create!(
  :summary => "tag pages look weird",
  :email => "guest@ao3.org",
  :url => "/tags",
  :authenticity_token => "OogoGee7oosheeciogie",
  :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.638.0 Safari/534.16",
  :ip_address => "72.14.204.103"
)
User.current_user = sam
ct7 = st18.needs_fix!
CodeCommit.create!(:author => "rodney", :message => "partial fix for issue 7", :pushed_at => Time.now)
User.current_user = sidra
ct7.reload.stage!
User.current_user = blair
ct7.verify!
User.current_user = sidra
ct7.deploy!(rn2.id)
rn2.post!

User.current_user = nil
st19 = SupportTicket.create!(
  :summary => "fanfiction.net is down",
  :email => "guest@ao3.org",
  :url => "/works/new",
  :authenticity_token => "OogoGee7oosheeciogie",
  :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.638.0 Safari/534.16",
  :ip_address => "72.14.204.103"
)
User.current_user = sidra
st19.resolve!("not our problem")

User.current_user = john
st20 = SupportTicket.create!(
  :summary => "anon is my name",
  :url => "/",
  :authenticity_token => "UuyohjeijeezooSh5eo5",
  :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_5; de-de) AppleWebKit/534.15+ (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4",
  :ip_address => "98.223.153.124"
)

User.current_user = dean
st21 = SupportTicket.create!(
  :summary => "please give me volunteer status",
  :anonymous => false,
  :url => "/support",
  :authenticity_token => "EeVei3Vahseijeangief",
  :user_agent => "Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  :ip_address => "71.111.1.40"
)
User.current_user = blair
st21.user_comment!("i thought he was leaving fandom forever", "private")
st21.needs_admin!
User.current_user = sam
st21.user_comment!("forever is a long time", "private")

User.current_user = nil
st22 = SupportTicket.create!(
  :summary => "when does yuletide 2011 open for prompts?",
  :email => "guest@ao3.org",
  :url => "/collections/yuletide2010",
  :authenticity_token => "OogoGee7oosheeciogie",
  :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.638.0 Safari/534.16",
  :ip_address => "72.14.204.103"
)
User.current_user = dean
comment = st22.user_comment!("see http://community.livejournal.com/yuletide_admin/")
User.current_user = nil
st22.accept!(comment.id, st22.authentication_code)

User.current_user = blair
ct8 = CodeTicket.create!(:summary => "patch the roof")
User.current_user = sam
ct8.duplicate!(ct1.id)
