class CreateTickets < ActiveRecord::Migration
  def self.up
    create_table :support_identities do |t|
      t.string   :name,       :null => false
      t.boolean  :official, :default => false

      t.timestamps
    end
    add_column :users, :support_identity_id, :integer

    create_table :support_tickets do |t|
      t.integer :user_id
      t.string :email
      t.string :authentication_code
      t.string :summary
      t.boolean :private, :default => false
      t.boolean :display_user_name, :default => false
      t.string :url
      t.string :archive_revision
      t.string :user_agent
      t.string :ip_address
      t.boolean :approved, :default => false, :null => false
      t.integer :support_identity_id
      t.boolean :question, :default => false
      t.integer :faq_id
      t.boolean :problem, :default => false
      t.integer :code_ticket_id
      t.boolean :admin, :default => false
      t.boolean :support_admin_resolved, :default => false
      t.boolean :comment, :default => false
      t.integer :resolved, :default => false

      t.integer :summary_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.timestamps
    end
    create_table :support_details do |t|
      t.integer :support_ticket_id
      t.integer :support_identity_id
      t.boolean :support_response, :default => false
      t.string :content
      t.boolean :private, :default => false
      t.boolean :resolved_ticket, :default => false

      t.integer :content_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.timestamps
    end
    create_table :support_notifications do |t|
      t.integer :support_ticket_id
      t.boolean :public_watcher, :default => false
      t.string :email

      t.timestamps
    end

    create_table :faqs, :force => true do |t|
      t.string   :title
      t.text     :content
      t.integer  :position,   :default => 1
      t.integer :user_id
      t.boolean :posted, :default => false

      t.integer :content_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.timestamps
    end

    create_table :faq_details do |t|
      t.integer :faq_id
      t.integer :support_identity_id
      t.boolean :support_response, :default => false
      t.string :content
      t.boolean :private, :default => false

      t.integer :content_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.timestamps
    end

    create_table :faq_votes do |t|
      t.integer :faq_id
      t.integer :support_ticket_id
      t.integer :vote, :limit => 1, :default => 1

      t.timestamps
    end

    create_table :code_tickets do |t|
      t.string :summary
      t.string :description
      t.string :url
      t.string :reported_rev
      t.string :committed_rev
      t.string :deployed_rev
      t.string :browser
      t.integer :support_identity_id
      t.integer :code_ticket_id
      t.integer :resolved, :default => false

      t.integer :summary_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.integer :description_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.timestamps
    end
    create_table :code_details do |t|
      t.integer :code_ticket_id
      t.integer :support_identity_id
      t.boolean :support_response, :default => false
      t.string :content
      t.boolean :private, :default => false
      t.boolean :resolved_ticket, :default => false
      t.string :archive_revision

      t.integer :content_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.timestamps
    end
    create_table :code_votes do |t|
      t.integer :code_ticket_id
      t.integer :user_id
      t.integer :support_ticket_id
      t.integer :vote, :limit => 1, :default => 1

      t.timestamps
    end
    create_table :code_notifications do |t|
      t.integer :code_ticket_id
      t.string :email

      t.timestamps
    end

    create_table :deploy_notes, :force => true do |t|
      t.string   :version
      t.text     :content
      t.string   :deployed_rev
      t.integer  :support_identity_id
      t.boolean  :posted, :default => false

      t.integer :content_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.timestamps
    end

  end

  def self.down
    drop_table :support_tickets
    drop_table :support_details
    drop_table :support_notifications
    drop_table :faqs
    drop_table :code_tickets
    drop_table :code_details
    drop_table :code_votes
    drop_table :code_notifications
    drop_column :users, :support_identity_id
  end
end
