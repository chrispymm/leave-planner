require "test_helper"

class CalendarControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:chris))
  end

  test "redirects to sign in when not authenticated" do
    sign_out
    get root_url
    assert_redirected_to new_session_path
  end

  test "should get show with default 12 months without top header" do
    travel_to Date.new(2026, 9, 16) do
      get root_url
      assert_response :success
      assert_select "header.site-nav", count: 0
      assert_select "turbo-frame#calendar_frame"
      assert_select ".calendar-year-title", text: "2026"
      assert_select ".month-card", count: 12
      assert_select ".month-card.past-month", count: 8
      assert_select ".month-card.current-month", count: 1
      assert_select ".month-card.current-month .month-header", text: "September"
      assert_select ".calendar-controls", text: /Selected Person:/, count: 0
      assert_select "a[href*='person_id=']", count: 0
    end
  end

  test "should navigate to the whole year containing start_date" do
    get calendar_url(start_date: "2027-06-15")
    assert_response :success
    assert_select ".calendar-year-title", text: "2027"
    assert_select ".month-card .month-header", text: "January"
    assert_select ".month-card .month-header", text: "December"
    assert_select "a[aria-label='Previous year'][href='#{calendar_path(start_date: "2026-01-01", reset_leave_year_details: 1)}']"
    assert_select "a[aria-label='Next year'][href='#{calendar_path(start_date: "2028-01-01", reset_leave_year_details: 1)}']"
  end

  test "should render alternate list layout via layout=list query param" do
    get calendar_url(start_date: "2026-01-01", layout: "list")
    assert_response :success
    assert_select ".calendar-list-12"
    assert_select ".month-list-row", count: 12
    assert_select ".month-card", count: 0
    assert_select ".calendar-grid-12", count: 0
    assert_select "a[aria-label='Previous year'][href*='layout=list']"
  end

  test "should show an initial balance in its current leave year only" do
    person = Person.create!(
      family: families(:pymm_family),
      name: "Chris",
      color: "#9333ea",
      allowance_unit: "days",
      allowance_amount: 30,
      hours_per_day: 7.5,
      include_bank_holidays: false,
      leave_year_start_month: 4,
      leave_year_start_day: 6,
      initial_remaining_allowance: 11,
      initial_allowance_date: Date.new(2026, 9, 1)
    )
    person.leave_entries.create!(date: Date.new(2026, 12, 1), half_day: "none")
    person.leave_entries.create!(date: Date.new(2027, 2, 1), half_day: "none")

    travel_to Date.new(2026, 9, 16) do
      get calendar_url(start_date: "2026-01-01")
      assert_response :success
      assert_select ".person-card", text: /#{person.name}/ do
        assert_select "details.leave-year-summary[data-leave-year='2025/26']", count: 0
        assert_select ".leave-year-summary[data-leave-year='2026/27'][open]" do
          assert_select ".stats-row", text: /Used:\s*2\/11 days/
          assert_select ".stats-row", text: /Remaining:\s*9 days/
        end
      end

      get calendar_url(start_date: "2027-01-01")
      assert_response :success
      assert_select ".person-card", text: /#{person.name}/ do
        assert_select ".leave-year-summary[data-leave-year='2026/27'][open]" do
          assert_select ".stats-row", text: /Used:\s*2\/11 days/
          assert_select ".stats-row", text: /Remaining:\s*9 days/
        end
        assert_select ".leave-year-summary[data-leave-year='2027/28']:not([open])", text: /Used:\s*0\/30 days/
      end

      get calendar_url(start_date: "2027-01-01", reset_leave_year_details: 1)
      assert_response :success
      assert_select ".person-card", text: /#{person.name}/ do
        assert_select ".leave-year-summary[data-leave-year='2026/27'][open][data-persistent-details-reset-value='true']"
        assert_select ".leave-year-summary[data-leave-year='2027/28']:not([open])[data-persistent-details-reset-value='true']"
      end
    end
  end

  test "should show edit person settings cog link and holiday calendar links in sidebar" do
    get root_url
    assert_response :success
    people.each do |person|
      assert_select "a[href='#{edit_person_path(person)}'][data-turbo-frame='_top']", text: "⚙️"
      assert_select "a[href='#{person_leave_ranges_path(person)}'][data-turbo-frame='_top']", text: person.name
    end

    assert_select "a[href='#{school_holidays_path}'][data-turbo-frame='_top']"
    assert_select "a[href='#{bank_holidays_path}'][data-turbo-frame='_top']"
  end

  test "bank holidays shown depend on the family's bank_holiday_division setting" do
    families(:pymm_family).update!(bank_holiday_division: "england-and-wales")
    get calendar_url(start_date: "2026-01-01")
    assert_response :success
    assert_select "a.day-cell.bank-holiday[href*='date=2026-11-30']", count: 0

    families(:pymm_family).update!(bank_holiday_division: "scotland")
    get calendar_url(start_date: "2026-01-01")
    assert_response :success
    assert_select "a.day-cell.bank-holiday[href*='date=2026-11-30']", count: 1
  end
end
