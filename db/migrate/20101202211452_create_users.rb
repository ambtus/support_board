class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string   "email",       :null => false
      t.string   "login",       :null => false
      t.datetime "activated_at"
      t.string   "crypted_password"
      t.string   "salt"
      t.string   "persistence_token"

      t.timestamps
    end

    create_table "roles" do |t|
      t.string   "name",              :limit => 40
      t.string   "authorizable_type", :limit => 40
      t.integer  "authorizable_id"

      t.timestamps
    end

    create_table "roles_users", :id => false do |t|
      t.integer  "user_id"
      t.integer  "role_id"

      t.timestamps
    end
  end


 def self.down
    drop_table :users
    drop_table :roles
    drop_table :roles_users
  end
end
