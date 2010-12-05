class CreateTickets < ActiveRecord::Migration
  def self.up
    create_table :support_tickets do |t|
      t.integer :user_id
      t.string :email
      t.string :authentication_code
      t.string :summary
      t.integer :summary_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.boolean :private, :default => false
      t.boolean :display_user_name, :default => false
      t.string :url
      t.string :archive_revision
      t.string :user_agent
      t.string :ip_address
      t.boolean :approved, :default => false, :null => false
      t.integer :pseud_id
      t.string :category
      t.integer :archive_faq_id
      t.integer :code_ticket_id
      t.integer :resolved, :default => false
      t.boolean :admin_resolved, :default => false

      t.timestamps
    end
    create_table :support_details do |t|
      t.integer :support_ticket_id
      t.integer :pseud_id
      t.boolean :support_response, :default => false
      t.string :content
      t.boolean :private, :default => false
      t.boolean :resolved_ticket, :default => false
      t.integer :content_sanitizer_version, :limit => 2, :default => 0, :null => false

      t.timestamps
    end
    create_table :support_watchers do |t|
      t.integer :support_ticket_id
      t.boolean :public_watcher, :default => false
      t.string :email

      t.timestamps
    end
    add_column :pseuds, :support_volunteer, :boolean
    add_column :archive_faqs, :user_id, :integer
    add_column :archive_faqs, :posted, :boolean

    create_table :code_tickets do |t|
      t.string :summary
      t.integer :summary_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.string :url
      t.string :archive_revision
      t.string :user_agent
      t.integer :pseud_id
      t.string :category
      t.boolean :resolved, :default => false
      t.integer :admin_post_id
      t.integer :known_issue_id

      t.timestamps
    end
    create_table :code_details do |t|
      t.integer :code_ticket_id
      t.integer :pseud_id
      t.boolean :support_response, :default => false
      t.string :content
      t.integer :content_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.boolean :private, :default => false
      t.boolean :resolved_ticket, :default => false
      t.string :archive_revision
      t.string :code_revision

      t.timestamps
    end
    create_table :code_votes do |t|
      t.integer :code_ticket_id
      t.integer :user_id
      t.integer :vote, :limit => 1

      t.timestamps
    end
    create_table :code_watchers do |t|
      t.integer :code_ticket_id
      t.string :email

      t.timestamps
    end
    add_column :admin_posts, :user_id, :integer
    add_column :admin_posts, :posted, :boolean
    add_column :known_issues, :user_id, :integer
    add_column :known_issues, :posted, :boolean
  end

  def self.down
    drop_table :support_tickets
    drop_table :support_details
    drop_table :support_watchers
    drop_table :code_tickets
    drop_table :code_details
    drop_table :code_votes
    drop_table :code_watchers
    remove_column :pseuds, :support_volunteer
    remove_column :archive_faqs, :user_id
    remove_column :archive_faqs, :posted
    remove_column :admin_posts, :user_id
    remove_column :admin_posts, :posted
    remove_column :known_issues, :user_id
    remove_column :known_issues, :posted
  end
end
