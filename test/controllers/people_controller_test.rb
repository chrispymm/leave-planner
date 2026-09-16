require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = people(:alice)
  end

  test "should get index" do
    get people_url
    assert_response :success
    assert_select "h2", "People & Allowances"
    assert_select "a[href='#{root_path}']", text: /Back to Calendar/
  end

  test "should get new" do
    get new_person_url
    assert_response :success
  end

  test "should create person with days and bank holiday toggle" do
    assert_difference("Person.count") do
      post people_url, params: {
        person: {
          name: "Dave",
          color: "#ea580c",
          allowance_unit: "days",
          allowance_amount: 28.0,
          hours_per_day: 8.0,
          include_bank_holidays: true,
          leave_year_start_month: 4,
          leave_year_start_day: 6
        }
      }
    end

    assert_redirected_to people_url
    person = Person.find_by(name: "Dave")
    assert person.include_bank_holidays?
    assert_equal "days", person.allowance_unit
    assert_equal 28.0, person.allowance_amount
    assert_equal 4, person.leave_year_start_month
    assert_equal 6, person.leave_year_start_day
  end

  test "should create person with hours" do
    assert_difference("Person.count") do
      post people_url, params: {
        person: {
          name: "Eve",
          color: "#7c3aed",
          allowance_unit: "hours",
          allowance_amount: 195.0,
          hours_per_day: 7.5,
          include_bank_holidays: false,
          leave_year_start_month: 1
        }
      }
    end

    assert_redirected_to people_url
    person = Person.find_by(name: "Eve")
    assert_equal "hours", person.allowance_unit
    assert_equal 195.0, person.allowance_amount
  end

  test "should create person with mid-year initial balance" do
    assert_difference("Person.count") do
      post people_url, params: {
        person: {
          name: "Frank",
          color: "#059669",
          allowance_unit: "days",
          allowance_amount: 25.0,
          initial_remaining_allowance: 12.5,
          initial_allowance_date: "2026-09-01",
          hours_per_day: 7.5,
          include_bank_holidays: false,
          leave_year_start_month: 1,
          leave_year_start_day: 1
        }
      }
    end

    assert_redirected_to people_url
    person = Person.find_by(name: "Frank")
    assert_equal 12.5, person.initial_remaining_allowance
    assert_equal Date.new(2026, 9, 1), person.initial_allowance_date
  end

  test "should get edit" do
    get edit_person_url(@person)
    assert_response :success
  end

  test "should update person" do
    patch person_url(@person), params: { person: { name: "Alice Updated", allowance_amount: 30.0 } }
    assert_redirected_to people_url
    assert_equal "Alice Updated", @person.reload.name
    assert_equal 30.0, @person.allowance_amount
  end

  test "should destroy person" do
    assert_difference("Person.count", -1) do
      delete person_url(@person)
    end

    assert_redirected_to people_url
  end
end
