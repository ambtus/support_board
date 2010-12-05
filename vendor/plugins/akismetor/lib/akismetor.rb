require 'singleton'
require 'net/http'

class Akismetor
  include Singleton

  attr_reader :blog, :key

  # Does a key-check on Akismet so you know you can actually use a specific key.
  # Returns "valid" or "invalid" depending on response.
  def self.valid_key?(attributes)
    self.instance.execute('verify-key', attributes)
  end

  # Does a comment-check on Akismet with the submitted hash.
  # Returns true or false depending on response.
  def self.spam?(attributes)
    self.instance.execute('comment-check', attributes) != "false"
  end

  # Does a submit-spam on Akismet with the submitted hash.
  # Use this when Akismet incorrectly approves a spam comment.
  def self.submit_spam(attributes)
    self.instance.execute('submit-spam', attributes)
  end

  # Does a submit-ham on Akismet with the submitted hash.
  # Use this for a false positive, when Akismet incorrectly rejects a normal comment.
  def self.submit_ham(attributes)
    self.instance.execute('submit-ham', attributes)
  end

  def self.blog=(blog)
    self.instance.instance_variable_set('@blog', blog)
  end

  def self.blog
    self.instance.instance_variable_get('@blog')
  end

  def self.key=(key)
    self.instance.instance_variable_set('@key', key)
  end

  def self.key
    self.instance.instance_variable_get('@key')
  end

  def execute(command, attributes)
    validate_attributes!

    host = "#{akismetor_attributes[:key]}." if akismetor_attributes[:key] && command != 'verify-key'
    http = Net::HTTP.new("#{host}rest.akismet.com", 80)
    http.post("/1.1/#{command}", attributes_for_post(akismetor_attributes(attributes)), http_headers).body
  end

  def akismetor_attributes(attributes = {})
    {
      :blog => blog,
      :key => key
    }.merge(attributes)
  end

  protected

  def validate_attributes!
    raise "You must set the blog url. Ex: http://www.myblog.com" if blog.nil? or blog !~ /^http:\/\/.*$/
    raise "You must set the key value. Go to http://wordpress.com and get your key" if key.nil?
  end

  private

  def http_headers
    {
      'User-Agent' => 'Akismetor Rails Plugin/1.1',
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
  end

  def attributes_for_post(attributes)
    result = attributes.map { |k, v| "#{k}=#{v}" }.join('&')
    URI.escape(result)
  end
end
