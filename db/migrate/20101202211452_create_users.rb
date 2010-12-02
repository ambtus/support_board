class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string   "email",       :null => false
      t.string   "login",       :null => false
      t.datetime "activated_at"
      t.string   "crypted_password"
      t.string   "salt"

      t.timestamps
    end

    create_table "pseuds" do |t|
      t.integer  "user_id"
      t.string   "name",       :null => false
      t.boolean  "is_default", :default => false

      t.timestamps
    end

    create_table "roles" do |t|
      t.string   "name",              :limit => 40
      t.string   "authorizable_type", :limit => 40
      t.integer  "authorizable_id"

      t.timestamps
    end
  end


 def self.down
    drop_table :users
    drop_table :pseuds
    drop_table :roles
  end
end