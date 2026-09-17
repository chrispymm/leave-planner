module CalendarHelper
  # Days of week starting on Monday (UK/European standard)
  DAY_NAMES = %w[Mon Tue Wed Thu Fri Sat Sun].freeze

  def month_grid_cells(month_date)
    first_day = month_date.beginning_of_month
    last_day = month_date.end_of_month

    # Monday is 1, Sunday is 7 in wday conversion: (wday + 6) % 7 gives Mon=0..Sun=6
    start_offset = (first_day.wday + 6) % 7
    total_days = last_day.day

    cells = []
    # Leading blanks
    start_offset.times { cells << nil }
    # Month dates
    (1..total_days).each do |d|
      cells << Date.new(month_date.year, month_date.month, d)
    end
    # Trailing blanks to complete final week
    remainder = cells.length % 7
    (7 - remainder).times { cells << nil } unless remainder.zero?

    cells
  end

  def leave_year_label(range)
    return range.begin.year.to_s if range.begin.year == range.end.year

    "#{range.begin.year}/#{range.end.strftime('%y')}"
  end
end
