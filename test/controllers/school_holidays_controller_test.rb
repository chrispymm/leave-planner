require "test_helper"

class SchoolHolidaysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @school_holiday = school_holidays(:summer)
  end

  test "should get index" do
    get school_holidays_url
    assert_response :success
  end

  test "should get new" do
    get new_school_holiday_url
    assert_response :success
  end

  test "should create school holiday" do
    assert_difference("SchoolHoliday.count") do
      post school_holidays_url, params: {
        school_holiday: {
          title: "Easter 2027",
          start_date: "2027-03-29",
          end_date: "2027-04-09",
          color: "#f59e0b"
        }
      }
    end

    assert_redirected_to school_holidays_url
  end

  test "should get edit" do
    get edit_school_holiday_url(@school_holiday)
    assert_response :success
  end

  test "should update school holiday" do
    patch school_holiday_url(@school_holiday), params: { school_holiday: { title: "Summer Updated" } }
    assert_redirected_to school_holidays_url
    assert_equal "Summer Updated", @school_holiday.reload.title
  end

  test "should destroy school holiday" do
    assert_difference("SchoolHoliday.count", -1) do
      delete school_holiday_url(@school_holiday)
    end

    assert_redirected_to school_holidays_url
  end
end
