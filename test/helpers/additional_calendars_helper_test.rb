require "test_helper"

class AdditionalCalendarsHelperTest < ActionView::TestCase
  test "keeps valid hex colours" do
    assert_equal "#f59e0b", safe_calendar_color("#f59e0b")
    assert_equal "#abc", safe_calendar_color("#abc")
  end

  test "rejects colours that could inject extra css declarations" do
    assert_equal AdditionalCalendar::DEFAULT_COLOR,
      safe_calendar_color("#fff; background-image: url(https://evil.test/x.png)")
    assert_equal AdditionalCalendar::DEFAULT_COLOR, safe_calendar_color("red")
    assert_equal AdditionalCalendar::DEFAULT_COLOR, safe_calendar_color(nil)
    assert_equal AdditionalCalendar::DEFAULT_COLOR, safe_calendar_color("")
  end

  test "swatch never renders an unsafe colour" do
    swatch = calendar_color_swatch("#fff; background-image: url(https://evil.test/x.png)")

    assert_no_match(/background-image/, swatch)
    assert_match(/background-color: #{Regexp.escape(AdditionalCalendar::DEFAULT_COLOR)}/, swatch)
  end

  test "band style never renders an unsafe colour" do
    entry = AdditionalCalendarEntry.new(
      additional_calendar: AdditionalCalendar.new(color: "#fff; background-image: url(https://evil.test/x.png)")
    )

    style = additional_calendar_band_style([ entry ])

    assert_no_match(/background-image/, style)
    assert_equal "box-shadow: inset 0 -3px 0 0 #{AdditionalCalendar::DEFAULT_COLOR};", style
  end
end
