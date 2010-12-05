require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/../lib/akismetor'

module AkismetorSpecHelper
  def valid_attributes
    {
      :user_ip => '200.10.20.30',
      :user_agent => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X 10.5; en-US; rv:1.9.0.3) Gecko/2008092414 Firefox/3.0.3',
      :referrer => 'http://www.previous-site.com', 
      :permalink => 'http://www.my-site.com',
      :comment_type => 'comment',
      :comment_author => 'Joe Dude',
      :comment_author_email => 'some-email@some-host.com',
      :comment_author_url => 'http://www.author-s-site.com',
      :comment_content => 'this is a normal comment'
    }
  end

  def invalid_attributes
    valid_attributes.with(:comment_author => 'viagra-test-123')
  end
end

describe Akismetor do
  include AkismetorSpecHelper
  
  before :each do
    Akismetor.blog = Akismetor.key = nil
  end
  
  describe 'assigning the config values' do
    it 'should assign the key value' do
      Akismetor.key = '123456789'
      Akismetor.key.should == '123456789'
    end
    
    it 'should assign the blog url' do
      Akismetor.blog = 'http://www.blog.com'
      Akismetor.blog.should == 'http://www.blog.com'
    end
  end
  
  describe 'on attributes validation' do
    it 'should raise an error when blog is empty' do
      lambda do
        Akismetor.valid_key?(valid_attributes) 
      end.should raise_error(RuntimeError, "You must set the blog url. Ex: http://www.myblog.com")
    end
    
    it 'should raise an error when blog url is wrong' do
      Akismetor.blog = 'blog.com'
      
      lambda do
        Akismetor.valid_key?(valid_attributes)
      end.should raise_error(RuntimeError, "You must set the blog url. Ex: http://www.myblog.com")
    end
    
    it 'should raise an error when key is empty' do
      Akismetor.blog = 'http://www.blog.com'
      
      lambda do
        Akismetor.valid_key?(valid_attributes) 
      end.should raise_error(RuntimeError, "You must set the key value. Go to http://wordpress.com and get your key")
    end
  end

  describe "in general" do

    before do
      Akismetor.key = '123456789'
      Akismetor.blog = 'http://www.blog.com'
    end

    def mock_akismet(value)
      @response = stub("response", :body => value)
      @http = stub("http", :post => @response)
    end

    it ".valid_key? should connect to host 'rest.akismet.com' " do
      mock_akismet('true')
      Net::HTTP.should_receive(:new).with('rest.akismet.com', anything()).and_return(@http)
      Akismetor.valid_key?(valid_attributes)
    end

    it ".spam? should connect to host '123456789.rest.akismet.com' " do
      mock_akismet('true')
      Net::HTTP.should_receive(:new).with('123456789.rest.akismet.com', anything()).and_return(@http)
      Akismetor.spam?(valid_attributes)
    end

    it ".spam? should convert Akismet's string 'true' to boolean true" do
      mock_akismet('true')
      Net::HTTP.should_receive(:new).and_return(@http)
      Akismetor.spam?(invalid_attributes).should be_true
    end

    it ".spam? should convert Akismet's string 'false' to boolean false" do
      mock_akismet('false')
      Net::HTTP.should_receive(:new).and_return(@http)
      Akismetor.spam?(invalid_attributes).should be_false
    end
  end

  describe "testing Akismet's commands" do
    
    before do
      Akismetor.key = '123456789'
      Akismetor.blog = 'http://www.blog.com'
    end

    before(:each) do
      @response = stub("response", :body => 'true')
      @http = stub("http", :post => @response)
      Net::HTTP.should_receive(:new).and_return(@http)
    end
    
    it ".valid_key? should run Akismet's command 'verify-key' " do
      @http.should_receive(:post).with('/1.1/verify-key', anything(), anything()).and_return(@response)
      Akismetor.valid_key?(valid_attributes)
    end

    it ".spam? should run Akismet's command 'comment-check' " do
      @http.should_receive(:post).with('/1.1/comment-check', anything(), anything()).and_return(@response)
      Akismetor.spam?(valid_attributes)
    end

    it ".submit_spam should run Akismet's command 'submit-spam' " do
      @http.should_receive(:post).with('/1.1/submit-spam', anything(), anything()).and_return(@response)
      Akismetor.submit_spam(valid_attributes)
    end

    it ".submit_ham should run Akismet's command 'submit-ham' " do
      @http.should_receive(:post).with('/1.1/submit-ham', anything(), anything()).and_return(@response)
      Akismetor.submit_ham(valid_attributes)
    end
  end
end
