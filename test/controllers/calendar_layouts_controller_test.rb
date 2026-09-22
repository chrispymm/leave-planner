require "test_helper"

class CalendarLayoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:chris))
  end

  test "updates the current user's layout and returns to the same calendar window" do
    patch calendar_layout_url, params: {
      calendar_layout: { layout: "list", start_date: default_start_date }
    }

    assert_redirected_to calendar_path
    assert_response :see_other
    assert_equal "list", users(:chris).reload.calendar_layout
    assert_equal "grid", users(:jess).reload.calendar_layout
  end

  test "rejects an invalid layout" do
    patch calendar_layout_url, params: {
      calendar_layout: { layout: "invalid", start_date: default_start_date }
    }

    assert_redirected_to calendar_path
    assert_response :see_other
    assert_equal "grid", users(:chris).reload.calendar_layout
    assert_equal "Calendar layout could not be updated.", flash[:alert]
  end

  test "keeps a non-default calendar window in the redirect" do
    patch calendar_layout_url, params: {
      calendar_layout: { layout: "list", start_date: "2030-03-01" }
    }

    assert_redirected_to calendar_path(start_date: "2030-03-01")
    assert_response :see_other
  end

  test "requires authentication" do
    sign_out

    patch calendar_layout_url, params: {
      calendar_layout: { layout: "list", start_date: "2026-08-01" }
    }

    assert_redirected_to new_session_path
  end

  private
    def default_start_date
      Date.current.prev_month.beginning_of_month.to_s
    end
end
