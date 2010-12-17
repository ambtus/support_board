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
john = User.create(:login => "john", :email => "john@ao3.org",
  :password => "secret", :password_confirmation => "secret")
jim = User.create(:login => "jim", :email => "jim@ao3.org",
  :password => "secret", :password_confirmation => "secret")

# support volunteers
sam = User.create(:login => "sam", :email => "sam@ao3.org",
  :password => "secret", :password_confirmation => "secret")
sam.support_volunteer = "1"
sam.pseuds.create(:name => "sammy", :support_volunteer => true)
rodney = User.create(:login => "rodney", :email => "rodney@ao3.org",
  :password => "secret", :password_confirmation => "secret")
rodney.support_volunteer = "1"
rodney.pseuds.create(:name => "3Phds", :support_volunteer => true)
blair = User.create(:login => "blair", :email => "blair@ao3.org",
  :password => "secret", :password_confirmation => "secret")
blair.support_volunteer = "1"
blair.pseuds.create(:name => "guide", :support_volunteer => true)

# support admin
rodney.support_admin = "1"
bofh = User.create(:login => "bofh", :email => "bofh@ao3.org",
  :password => "secret", :password_confirmation => "secret")
bofh.support_admin = "1"

# code tickets
CodeTicket.create(:summary => "save the world", :pseud_id => sam.support_pseud.id)
CodeTicket.create(:summary => "build a zpm", :pseud_id => rodney.support_pseud.id)
CodeTicket.create(:summary => "find a sentinel", :pseud_id => blair.support_pseud.id)
dada = CodeTicket.create(:summary => "repeal DADA")

# support tickets
SupportTicket.create(:summary => "some problem", :email => "guest@ao3.org", :problem => true)
SupportTicket.create(:summary => "a personal problem", :email => "guest@ao3.org", :private => true)
SupportTicket.create(:summary => "where's the salt?", :user_id => dean.id)
SupportTicket.create(:summary => "repeal DADA", :user_id => john.id, :private =>true, :code_ticket_id => dada.id)
SupportTicket.create(:summary => "what's my password?", :user_id => john.id, :private =>true, :display_user_name => true)
SupportTicket.create(:summary => "what's wrong with me?", :user_id => jim.id, :private =>true)

# faqs
faq1 = ArchiveFaq.create(:title => "where to find salt", :position => 1, :posted => true)
faq1.update_attribute(:posted, true)
faq1.update_attribute(:user_id, bofh.id)
faq2 = ArchiveFaq.create(:title => "why we don't have enough ZPMs", :position => 2, :posted => true, :user_id => rodney.id)
faq2.update_attribute(:posted, true)
faq2.update_attribute(:user_id, rodney.id)
faq3 =ArchiveFaq.create(:title => "what's DADA?", :position => 3, :posted => true)
faq3.update_attribute(:posted, true)
faq3.update_attribute(:user_id, rodney.id)
ArchiveFaq.create(:title => "how to recover your password", :position => 4, :user_id => sam.id)
ArchiveFaq.create(:title => "what's a sentinel?", :position => 5, :user_id => blair.id)
