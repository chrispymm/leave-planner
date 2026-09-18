class CalendarController < ApplicationController
  def show
    @reset_leave_year_details = params[:reset_leave_year_details] == "1"
    @layout = params[:layout] == "list" ? "list" : "grid"
    @layout_params = @layout == "list" ? { layout: "list" } : {}

    if params[:start_date].present?
      begin
        @start_date = Date.parse(params[:start_date]).beginning_of_year
      rescue ArgumentError
        @start_date = Date.current.beginning_of_year
      end
    else
      @start_date = Date.current.beginning_of_year
    end

    @months = (0...12).map { |i| @start_date + i.months }
    @window_start = @start_date
    @window_end = @start_date.end_of_year

    @people = Current.account.people.order(:name)
    @allowance_ranges_by_person = @people.index_with do |person|
      person.leave_year_ranges_overlapping(@window_start..@window_end).reject do |leave_year_range|
        leave_year_range.end < Date.current
      end
    end
    division = Current.account.bank_holiday_division
    @bank_holidays_map = BankHoliday.map_by_date(@window_start, @window_end, division)
    @bank_holidays_set = BankHoliday.dates_set(@window_start, @window_end, division)
    @school_holidays_map = Current.account.school_holidays.map_by_date(@window_start, @window_end)
    @leave_entries_by_date = LeaveEntry.where(person: @people, date: @window_start..@window_end).includes(:person).group_by(&:date)
  end
end
