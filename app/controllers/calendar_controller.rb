class CalendarController < ApplicationController
  def show
    @reset_leave_year_details = params[:reset_leave_year_details] == "1"
    @layout = Current.user.calendar_layout

    @start_date = calendar_start_date_from(params[:start_date])

    @months = (0...12).map { |i| @start_date + i.months }
    @window_start = @start_date
    @window_end = (@start_date + 11.months).end_of_month
    @year_title = [ @window_start.year, @window_end.year ].uniq.join("–")

    @people = Current.account.people.order(:name)
    @allowance_ranges_by_person = @people.index_with do |person|
      person.leave_year_ranges_overlapping(@window_start..@window_end).reject do |leave_year_range|
        leave_year_range.end < Date.current
      end
    end
    division = Current.account.bank_holiday_division
    @bank_holidays_map = BankHoliday.map_by_date(@window_start, @window_end, division)
    @bank_holidays_set = BankHoliday.dates_set(@window_start, @window_end, division)
    @additional_calendar_entries_map = Current.account.additional_calendar_entries.map_by_date(@window_start, @window_end)
    @additional_calendars = Current.account.additional_calendars.alphabetical
    @leave_entries_by_date = LeaveEntry.where(person: @people, date: @window_start..@window_end).includes(:person).group_by(&:date)
  end
end
