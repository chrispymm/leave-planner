class CalendarController < ApplicationController
  def show
    if params[:start_date].present?
      begin
        @start_date = Date.parse(params[:start_date]).beginning_of_month
      rescue ArgumentError
        @start_date = Date.current.beginning_of_month
      end
    else
      @start_date = Date.current.beginning_of_month
    end

    @months_count = 12
    @months = (0...@months_count).map { |i| @start_date + i.months }
    @window_start = @start_date
    @window_end = (@start_date + (@months_count - 1).months).end_of_month

    @people = Person.order(:name)
    @bank_holidays_map = BankHoliday.map_by_date(@window_start, @window_end)
    @bank_holidays_set = BankHoliday.dates_set(@window_start, @window_end)
    @school_holidays_map = SchoolHoliday.map_by_date(@window_start, @window_end)
    @leave_entries_by_date = LeaveEntry.where(date: @window_start..@window_end).includes(:person).group_by(&:date)

    # Active person filter for quick-booking (defaults to first person if available)
    @selected_person_id = params[:person_id].presence || @people.first&.id
    @selected_person = @people.find_by(id: @selected_person_id) || @people.first
  end
end
