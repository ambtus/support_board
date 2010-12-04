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

  create_table "admin_posts", :force => true do |t|
    t.integer  "admin_id"
    t.string   "title"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.boolean  "posted"
  end

  create_table "admins", :force => true do |t|
    t.string   "email",             :null => false
    t.string   "login",             :null => false
    t.datetime "activated_at"
    t.string   "crypted_password"
    t.string   "salt"
    t.string   "persistence_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "archive_faqs", :force => true do |t|
    t.integer  "admin_id"
    t.string   "title"
    t.text     "content"
    t.integer  "position",   :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.boolean  "posted"
  end

  create_table "code_details", :force => true do |t|
    t.integer  "code_ticket_id"
    t.integer  "pseud_id"
    t.boolean  "support_response",                       :default => false
    t.string   "content"
    t.integer  "content_sanitizer_version", :limit => 2, :default => 0,     :null => false
    t.boolean  "private",                                :default => false
    t.boolean  "resolved_ticket",                        :default => false
    t.string   "archive_revision"
    t.string   "code_revision"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "code_tickets", :force => true do |t|
    t.string   "summary"
    t.integer  "summary_sanitizer_version", :limit => 2, :default => 0,     :null => false
    t.string   "url"
    t.string   "archive_revision"
    t.string   "user_agent"
    t.integer  "pseud_id"
    t.string   "category"
    t.boolean  "resolved",                               :default => false
    t.integer  "admin_post_id"
    t.integer  "known_issue_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "code_votes", :force => true do |t|
    t.integer  "code_ticket_id"
    t.integer  "user_id"
    t.integer  "vote",           :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "code_watchers", :force => true do |t|
    t.integer  "code_ticket_id"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "known_issues", :force => true do |t|
    t.integer  "admin_id"
    t.string   "title"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.boolean  "posted"
  end

  create_table "pseuds", :force => true do |t|
    t.integer  "user_id"
    t.string   "name",                                 :null => false
    t.boolean  "is_default",        :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "support_volunteer"
  end

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
    t.integer  "pseud_id"
    t.boolean  "support_response",                       :default => false
    t.string   "content"
    t.boolean  "private",                                :default => false
    t.boolean  "resolved_ticket",                        :default => false
    t.integer  "content_sanitizer_version", :limit => 2, :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "support_tickets", :force => true do |t|
    t.integer  "user_id"
    t.string   "email"
    t.string   "authentication_code"
    t.string   "summary"
    t.integer  "summary_sanitizer_version", :limit => 2, :default => 0,     :null => false
    t.boolean  "private",                                :default => false
    t.boolean  "display_user_name",                      :default => false
    t.string   "url"
    t.string   "archive_revision"
    t.string   "user_agent"
    t.string   "ip_address"
    t.boolean  "approved",                               :default => false, :null => false
    t.integer  "pseud_id"
    t.string   "category"
    t.integer  "archive_faq_id"
    t.integer  "code_ticket_id"
    t.integer  "owner_resolved",                         :default => 0
    t.boolean  "support_resolved",                       :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "support_watchers", :force => true do |t|
    t.integer  "support_ticket_id"
    t.boolean  "public_watcher",    :default => false
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",             :null => false
    t.string   "login",             :null => false
    t.datetime "activated_at"
    t.string   "crypted_password"
    t.string   "salt"
    t.string   "persistence_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
