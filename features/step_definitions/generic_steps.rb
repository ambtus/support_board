When 'I reload the page' do
  visit current_url
end

Then /^(?:|I )should be at the url (.+)$/ do |url|
  wanted_path = URI.parse("http://www.example.com#{url}")
  current_path = URI.parse(current_url)
  if current_path.respond_to? :should
    current_path.should == wanted_path
  else
    assert_equal wanted_path, current_path
  end
end

Given /^I wait (\d+) seconds?$/ do |number|
  Kernel::sleep number.to_i
end
