require 'test_helper'

class CodeTicketCommentsTest < ActiveSupport::TestCase
  test "system_log comments" do
    assert_equal %Q{unowned -> taken}, CodeTicket.find(2).code_details.last.content
    assert_equal %Q{staged -> verified}, CodeTicket.find(3).code_details.last.content
    assert_equal %Q{committed -> staged}, CodeTicket.find(4).code_details.last.content
    assert_equal %Q{taken -> committed (4)}, CodeTicket.find(5).code_details.last.content
    assert_match %Q{verified -> closed (1)}, CodeTicket.find(6).code_details.last.content
  end
  test "comment on unowned ticket" do
    ticket = CodeTicket.find(1)
    User.current_user = nil
    assert_raise(RuntimeError) { ticket.comment!("something") }
    assert_equal 0, ticket.code_details.count
    User.current_user = User.find_by_login("dean")
    assert ticket.comment!("user")
    assert_equal 1, ticket.code_details.count
    assert_match "dean wrote", ticket.code_details.first.info
    assert_equal "user", ticket.code_details.first.content
    User.current_user = User.find_by_login("sam")
    assert ticket.comment!("volunteer")
    assert_equal 2, ticket.code_details.count
    assert_match "sam (volunteer) wrote", ticket.code_details.last.info
    assert_equal "volunteer", ticket.code_details.last.content
    assert ticket.comment!("unofficial volunteer", false)
    assert_equal 3, ticket.code_details.count
    assert_match "sam wrote", ticket.code_details.last.info
    assert_equal "unofficial volunteer", ticket.code_details.last.content
  end
  test "comment on owned ticket" do
    ticket = CodeTicket.find(2)
    assert_equal 1, ticket.code_details.count
    User.current_user = User.find_by_login("dean")
    assert_raise(RuntimeError) { ticket.comment!("something") }
    assert_equal 1, ticket.code_details.count
    User.current_user = User.find_by_login("sam")
    assert ticket.comment!("important stuff")
    assert_equal 2, ticket.code_details.count
    assert_equal "important stuff", ticket.code_details.last.content
    assert_match "sam (volunteer) wrote", ticket.code_details.last.info
    assert_raise(RuntimeError) { ticket.comment!("unofficial comment", false) }
    assert_equal 2, ticket.code_details.count
  end
end
