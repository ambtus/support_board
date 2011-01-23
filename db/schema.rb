# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101203221944) do

  create_table "code_commits", :force => true do |t|
    t.string   "author"
    t.string   "url"
    t.string   "message"
    t.datetime "pushed_at"
    t.integer  "code_ticket_id"
    t.integer  "support_identity_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "code_commits", ["code_ticket_id"], :name => "index_code_commits_on_code_ticket_id"
  add_index "code_commits", ["status"], :name => "index_code_commits_on_status"
  add_index "code_commits", ["support_identity_id"], :name => "index_code_commits_on_support_identity_id"

  create_table "code_details", :force => true do |t|
    t.integer  "code_ticket_id"
    t.integer  "support_identity_id"
    t.boolean  "support_response",                       :default => false
    t.boolean  "system_log",                             :default => false
    t.string   "content",                                :default => ""
    t.boolean  "private",                                :default => false
    t.integer  "content_sanitizer_version", :limit => 2, :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "code_details", ["code_ticket_id"], :name => "index_code_details_on_code_ticket_id"
  add_index "code_details", ["private"], :name => "index_code_details_on_private"
  add_index "code_details", ["support_identity_id"], :name => "index_code_details_on_support_identity_id"
  add_index "code_details", ["support_response"], :name => "index_code_details_on_support_response"
  add_index "code_details", ["system_log"], :name => "index_code_details_on_system_log"

  create_table "code_notifications", :force => true do |t|
    t.integer  "code_ticket_id"
    t.string   "email"
    t.boolean  "official",       :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "code_notifications", ["code_ticket_id"], :name => "index_code_notifications_on_code_ticket_id"
  add_index "code_notifications", ["email"], :name => "index_code_notifications_on_email"
  add_index "code_notifications", ["official"], :name => "index_code_notifications_on_official"

  create_table "code_tickets", :force => true do |t|
    t.string   "summary",                   :limit => 256, :default => ""
    t.string   "url"
    t.string   "browser"
    t.string   "status"
    t.integer  "support_identity_id"
    t.integer  "code_ticket_id"
    t.integer  "release_note_id"
    t.integer  "summary_sanitizer_version", :limit => 2,   :default => 0,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "code_tickets", ["code_ticket_id"], :name => "index_code_tickets_on_code_ticket_id"
  add_index "code_tickets", ["release_note_id"], :name => "index_code_tickets_on_release_note_id"
  add_index "code_tickets", ["status"], :name => "index_code_tickets_on_status"
  add_index "code_tickets", ["support_identity_id"], :name => "index_code_tickets_on_support_identity_id"

  create_table "code_votes", :force => true do |t|
    t.integer  "code_ticket_id"
    t.integer  "user_id"
    t.integer  "support_ticket_id"
    t.integer  "vote",              :limit => 1, :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "code_votes", ["code_ticket_id"], :name => "index_code_votes_on_code_ticket_id"
  add_index "code_votes", ["support_ticket_id"], :name => "index_code_votes_on_support_ticket_id"
  add_index "code_votes", ["user_id"], :name => "index_code_votes_on_user_id"

  create_table "faq_details", :force => true do |t|
    t.integer  "faq_id"
    t.integer  "support_identity_id"
    t.boolean  "support_response",                       :default => false
    t.string   "content",                                :default => ""
    t.boolean  "private",                                :default => false
    t.boolean  "system_log",                             :default => false
    t.integer  "content_sanitizer_version", :limit => 2, :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "faq_details", ["faq_id"], :name => "index_faq_details_on_faq_id"
  add_index "faq_details", ["private"], :name => "index_faq_details_on_private"
  add_index "faq_details", ["support_identity_id"], :name => "index_faq_details_on_support_identity_id"
  add_index "faq_details", ["support_response"], :name => "index_faq_details_on_support_response"
  add_index "faq_details", ["system_log"], :name => "index_faq_details_on_system_log"

  create_table "faq_notifications", :force => true do |t|
    t.integer  "faq_id"
    t.string   "email"
    t.boolean  "official",   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "faq_notifications", ["email"], :name => "index_faq_notifications_on_email"
  add_index "faq_notifications", ["faq_id"], :name => "index_faq_notifications_on_faq_id"
  add_index "faq_notifications", ["official"], :name => "index_faq_notifications_on_official"

  create_table "faq_votes", :force => true do |t|
    t.integer  "faq_id"
    t.integer  "support_ticket_id"
    t.integer  "vote",              :limit => 1, :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "faq_votes", ["faq_id"], :name => "index_faq_votes_on_faq_id"
  add_index "faq_votes", ["support_ticket_id"], :name => "index_faq_votes_on_support_ticket_id"

  create_table "faqs", :force => true do |t|
    t.string   "summary",                   :limit => 256, :default => ""
    t.text     "content"
    t.integer  "position"
    t.string   "status"
    t.integer  "content_sanitizer_version", :limit => 2,   :default => 0,  :null => false
    t.integer  "summary_sanitizer_version", :limit => 2,   :default => 0,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "faqs", ["position"], :name => "index_faqs_on_position"
  add_index "faqs", ["status"], :name => "index_faqs_on_status"

  create_table "release_notes", :force => true do |t|
    t.string   "release"
    t.text     "content"
    t.boolean  "posted",                                 :default => false
    t.integer  "content_sanitizer_version", :limit => 2, :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "release_notes", ["posted"], :name => "index_release_notes_on_posted"

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "authorizable_type", :limit => 40
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "support_details", :force => true do |t|
    t.integer  "support_ticket_id"
    t.integer  "support_identity_id"
    t.boolean  "support_response",                       :default => false
    t.string   "content",                                :default => ""
    t.boolean  "private",                                :default => false
    t.boolean  "resolved_ticket",                        :default => false
    t.boolean  "system_log",                             :default => false
    t.integer  "content_sanitizer_version", :limit => 2, :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "support_details", ["private"], :name => "index_support_details_on_private"
  add_index "support_details", ["support_identity_id"], :name => "index_support_details_on_support_identity_id"
  add_index "support_details", ["support_response"], :name => "index_support_details_on_support_response"
  add_index "support_details", ["support_ticket_id"], :name => "index_support_details_on_support_ticket_id"
  add_index "support_details", ["system_log"], :name => "index_support_details_on_system_log"

  create_table "support_identities", :force => true do |t|
    t.string   "name",                          :null => false
    t.boolean  "official",   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "support_identities", ["name"], :name => "index_support_identities_on_name"
  add_index "support_identities", ["official"], :name => "index_support_identities_on_official"

  create_table "support_notifications", :force => true do |t|
    t.integer  "support_ticket_id"
    t.boolean  "public_watcher",    :default => false
    t.string   "email"
    t.boolean  "official",          :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "support_notifications", ["email"], :name => "index_support_notifications_on_email"
  add_index "support_notifications", ["official"], :name => "index_support_notifications_on_official"
  add_index "support_notifications", ["public_watcher"], :name => "index_support_notifications_on_public_watcher"
  add_index "support_notifications", ["support_ticket_id"], :name => "index_support_notifications_on_support_ticket_id"

  create_table "support_tickets", :force => true do |t|
    t.integer  "user_id"
    t.string   "email"
    t.string   "authentication_code"
    t.string   "summary",                   :limit => 256, :default => ""
    t.boolean  "private",                                  :default => false
    t.boolean  "anonymous",                                :default => true
    t.string   "url"
    t.string   "user_agent"
    t.string   "ip_address"
    t.string   "authenticity_token"
    t.string   "browser"
    t.string   "status"
    t.integer  "support_identity_id"
    t.integer  "faq_id"
    t.integer  "code_ticket_id"
    t.integer  "summary_sanitizer_version", :limit => 2,   :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "support_tickets", ["anonymous"], :name => "index_support_tickets_on_anonymous"
  add_index "support_tickets", ["authentication_code"], :name => "index_support_tickets_on_authentication_code"
  add_index "support_tickets", ["code_ticket_id"], :name => "index_support_tickets_on_code_ticket_id"
  add_index "support_tickets", ["email"], :name => "index_support_tickets_on_email"
  add_index "support_tickets", ["faq_id"], :name => "index_support_tickets_on_faq_id"
  add_index "support_tickets", ["private"], :name => "index_support_tickets_on_private"
  add_index "support_tickets", ["status"], :name => "index_support_tickets_on_status"
  add_index "support_tickets", ["support_identity_id"], :name => "index_support_tickets_on_support_identity_id"
  add_index "support_tickets", ["user_id"], :name => "index_support_tickets_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "email",               :null => false
    t.string   "login",               :null => false
    t.datetime "activated_at"
    t.string   "crypted_password"
    t.string   "salt"
    t.string   "persistence_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "support_identity_id"
  end

  add_index "users", ["support_identity_id"], :name => "index_users_on_support_identity_id"

end
