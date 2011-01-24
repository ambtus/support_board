class CreateTickets < ActiveRecord::Migration

# TODO add names to notifications so can send email with names (looks less like spam)
# TODO change _notifications to _watchers (notifications are the things you send, watcher are the people you send them to)

  def self.up
    create_table :support_identities do |t|
      t.string   :name,       :null => false
      t.boolean  :official, :default => false

      t.timestamps
    end
    add_index :support_identities, :name
    add_index :support_identities, :official

    add_column :users, :support_identity_id, :integer
    add_index :users, :support_identity_id

    create_table :support_tickets do |t|
      t.integer :user_id
      t.string :email
      t.string :authentication_code
      t.string :summary, :limit => 256, :default => ""
      t.boolean :private, :default => false
      t.boolean :anonymous, :default => true
      t.string :url
      t.string :user_agent
      t.string :ip_address
      t.string :authenticity_token
      t.string :browser

      t.string :status
      t.integer :support_identity_id
      t.integer :faq_id
      t.integer :code_ticket_id

      t.integer :summary_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.timestamps
    end
    add_index :support_tickets, :user_id
    add_index :support_tickets, :email
    add_index :support_tickets, :authentication_code
    add_index :support_tickets, :private
    add_index :support_tickets, :anonymous
    add_index :support_tickets, :status
    add_index :support_tickets, :support_identity_id
    add_index :support_tickets, :faq_id
    add_index :support_tickets, :code_ticket_id


    create_table :support_details do |t|
      t.integer :support_ticket_id
      t.integer :support_identity_id
      t.boolean :support_response, :default => false
      t.string :content, :default => ""
      t.boolean :private, :default => false
      t.boolean :resolved_ticket, :default => false
      t.boolean  :system_log, :default => false

      t.integer :content_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.timestamps
    end
    add_index :support_details, :support_ticket_id
    add_index :support_details, :support_identity_id
    add_index :support_details, :support_response
    add_index :support_details, :private
    add_index :support_details, :system_log

    create_table :support_notifications do |t|
      t.integer :support_ticket_id
      t.boolean :public_watcher, :default => false
      t.string :email
      t.boolean :official, :default => false

      t.timestamps
    end
    add_index :support_notifications, :support_ticket_id
    add_index :support_notifications, :public_watcher
    add_index :support_notifications, :email
    add_index :support_notifications, :official

    create_table :faqs, :force => true do |t|
      t.string   :summary, :limit => 256, :default => ""
      t.text     :content, :default => ""
      t.integer  :position
      t.string   :status

      t.integer :content_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.integer :summary_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.timestamps
    end
    add_index :faqs, :position
    add_index :faqs, :status

    create_table :faq_details do |t|
      t.integer :faq_id
      t.integer :support_identity_id
      t.boolean :support_response, :default => false
      t.string :content, :default => ""
      t.boolean :private, :default => false
      t.boolean  :system_log, :default => false

      t.integer :content_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.timestamps
    end
    add_index :faq_details, :faq_id
    add_index :faq_details, :support_identity_id
    add_index :faq_details, :support_response
    add_index :faq_details, :private
    add_index :faq_details, :system_log

    create_table :faq_votes do |t|
      t.integer :faq_id
      t.integer :support_ticket_id
      t.integer :vote, :limit => 1, :default => 1

      t.timestamps
    end
    add_index :faq_votes, :faq_id
    add_index :faq_votes, :support_ticket_id

    create_table :faq_notifications do |t|
      t.integer :faq_id
      t.string :email
      t.boolean :official, :default => false

      t.timestamps
    end
    add_index :faq_notifications, :faq_id
    add_index :faq_notifications, :email
    add_index :faq_notifications, :official

    create_table :code_tickets do |t|
      t.string :summary, :limit => 256, :default => ""
      t.string :url
      t.string  :browser

      t.string :status
      t.integer :support_identity_id
      t.integer :code_ticket_id
      t.integer :release_note_id

      t.integer :summary_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.timestamps
    end
    add_index :code_tickets, :status
    add_index :code_tickets, :support_identity_id
    add_index :code_tickets, :code_ticket_id
    add_index :code_tickets, :release_note_id

    create_table :code_details do |t|
      t.integer  :code_ticket_id
      t.integer  :support_identity_id
      t.boolean  :support_response, :default => false
      t.boolean  :system_log, :default => false
      t.string   :content, :default => ""
      t.boolean  :private, :default => false

      t.integer  :content_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.timestamps
    end
    add_index :code_details, :code_ticket_id
    add_index :code_details, :support_identity_id
    add_index :code_details, :support_response
    add_index :code_details, :system_log
    add_index :code_details, :private

    create_table :code_votes do |t|
      t.integer :code_ticket_id
      t.integer :user_id
      t.integer :support_ticket_id
      t.integer :vote, :limit => 1, :default => 1

      t.timestamps
    end
    add_index :code_votes, :code_ticket_id
    add_index :code_votes, :user_id
    add_index :code_votes, :support_ticket_id

    create_table :code_notifications do |t|
      t.integer :code_ticket_id
      t.string :email
      t.boolean :official, :default => false

      t.timestamps
    end
    add_index :code_notifications, :code_ticket_id
    add_index :code_notifications, :email
    add_index :code_notifications, :official

    create_table :code_commits do |t|
      t.string :author
      t.string :url
      t.string :message
      t.timestamp :pushed_at
      t.integer :code_ticket_id
      t.integer :support_identity_id
      t.string  :status

      t.timestamps
    end
    add_index :code_commits, :code_ticket_id
    add_index :code_commits, :support_identity_id
    add_index :code_commits, :status

    create_table :release_notes, :force => true do |t|
      t.string   :release
      t.text     :content, :default => ""
      t.boolean  :posted, :default => false

      t.integer :content_sanitizer_version, :limit => 2, :default => 0, :null => false
      t.timestamps
    end
    add_index :release_notes, :posted

  end

  def self.down
    drop_table :support_identities
    drop_table :support_tickets
    drop_table :support_details
    drop_table :support_notifications
    drop_table :faqs
    drop_table :faq_details
    drop_table :faq_votes
    drop_table :faq_notifications
    drop_table :code_tickets
    drop_table :code_details
    drop_table :code_votes
    drop_table :code_notifications
    drop_table :release_notes
    drop_column :users, :support_identity_id
  end
end
