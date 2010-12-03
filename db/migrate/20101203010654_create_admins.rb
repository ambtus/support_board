class CreateAdmins < ActiveRecord::Migration
  def self.up
    create_table :admins do |t|
      t.string   "email",       :null => false
      t.string   "login",       :null => false
      t.datetime "activated_at"
      t.string   "crypted_password"
      t.string   "salt"
      t.string   "persistence_token"

      t.timestamps
    end

    create_table "admin_posts", :force => true do |t|
      t.integer  "admin_id"
      t.string   "title"
      t.text     "content"

      t.timestamps
    end
  end

    create_table "archive_faqs", :force => true do |t|
      t.integer  "admin_id"
      t.string   "title"
      t.text     "content"
      t.integer  "position",   :default => 1

      t.timestamps
    end

    create_table "known_issues", :force => true do |t|
      t.integer  "admin_id"
      t.string   "title"
      t.text     "content"

      t.timestamps
    end

  def self.down
    drop_table :admin_posts
    drop_table :archive_faqs
    drop_table :known_issues
  end
end
