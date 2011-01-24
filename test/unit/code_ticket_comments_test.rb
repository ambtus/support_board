require 'test_helper'

class CodeTicketCommentsTest < ActiveSupport::TestCase
  test "visible_code_details" do
    ticket = CodeTicket.find(4)
    assert_equal 4, ticket.visible_code_details.size
    User.current_user = User.find_by_login("jim")
    assert_equal 4, ticket.visible_code_details.size
    User.current_user = User.find_by_login("sam")
    assert_equal 7, ticket.visible_code_details.size
  end
  test "system_log comments" do
    assert_equal %Q{unowned -> taken}, CodeTicket.find(2).code_details.last.content
    assert_equal %Q{staged -> verified}, CodeTicket.find(3).code_details.last.content
    assert_equal %Q{committed -> staged}, CodeTicket.find(4).code_details.last.content
    assert_equal %Q{taken -> committed (4)}, CodeTicket.find(5).code_details.last.content
    assert_match %Q{verified -> closed (1)}, CodeTicket.find(6).code_details.last.content
  end
  test "guest comment on unowned ticket" do
    ticket = CodeTicket.find(1)
    User.current_user = nil
    assert_raise(SecurityError) { ticket.comment!("something") }
  end
  test "user comment on unowned ticket" do
    ticket = CodeTicket.find(1)
    assert_equal 0, ticket.code_details.count
    User.current_user = User.find_by_login("dean")
    assert ticket.comment!("something")
    assert_equal 1, ticket.code_details.count
    assert_match "dean wrote", ticket.code_details.last.info
    assert_equal "something", ticket.code_details.last.content
  end
  test "user private comment ticket" do
    ticket = CodeTicket.find(1)
    User.current_user = User.find_by_login("dean")
    assert_raise(SecurityError) { ticket.comment!("something", "private") }
  end
  test "volunteer comment unofficially on unowned ticket" do
    ticket = CodeTicket.find(1)
    User.current_user = User.find_by_login("sam")
    assert ticket.comment!("something", "unofficial")
    assert_match "sam wrote", ticket.code_details.last.info
  end
  test "volunteer comment officially on unowned ticket" do
    ticket = CodeTicket.find(1)
    User.current_user = User.find_by_login("sam")
    assert ticket.comment!("something")
    assert_match "sam (volunteer) wrote", ticket.code_details.last.info
    assert ticket.comment!("more stuff", "official")
    assert_match "sam (volunteer) wrote", ticket.code_details.last.info
  end
  test "volunteer private official comment on unowned ticket" do
    ticket = CodeTicket.find(1)
    User.current_user = User.find_by_login("sam")
    assert ticket.comment!("something", "private")
    assert_match "sam (volunteer) wrote [private]", ticket.code_details.last.info
  end
  test "guest comment on owned ticket" do
    ticket = CodeTicket.find(3)
    User.current_user = nil
    assert_raise(SecurityError) { ticket.comment!("something") }
  end
  test "user comment on owned ticket" do
    ticket = CodeTicket.find(3)
    User.current_user = User.find_by_login("dean")
    assert_raise(RuntimeError) { ticket.comment!("something") }
  end
  test "volunteer comment unofficially on owned ticket" do
    ticket = CodeTicket.find(3)
    User.current_user = User.find_by_login("sam")
    assert_raise(RuntimeError) { ticket.comment!("something", "unofficial") }
  end
  test "volunteer comment officially on owned ticket" do
    ticket = CodeTicket.find(3)
    User.current_user = User.find_by_login("sam")
    assert ticket.comment!("something")
    assert_match "sam (volunteer) wrote", ticket.code_details.last.info
    assert_match "something", ticket.code_details.last.content
  end
  test "volunteer private official comment on owned ticket" do
    ticket = CodeTicket.find(3)
    User.current_user = User.find_by_login("sam")
    assert ticket.comment!("something", "private")
    assert_match "sam (volunteer) wrote [private]", ticket.code_details.last.info
  end
end
