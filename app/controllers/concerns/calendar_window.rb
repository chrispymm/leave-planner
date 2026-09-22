module CalendarWindow
  extend ActiveSupport::Concern

  included do
    helper_method :default_calendar_start_date, :calendar_path_for
  end

  # The calendar window the app opens on: the month before the current one.
  def default_calendar_start_date
    Date.current.prev_month.beginning_of_month
  end

  def calendar_start_date_from(value)
    return default_calendar_start_date if value.blank?
    return value.beginning_of_month if value.respond_to?(:beginning_of_month)

    Date.parse(value.to_s).beginning_of_month
  rescue ArgumentError, TypeError
    default_calendar_start_date
  end

  # Only carries start_date when it differs from the default window, so the
  # common case stays on a clean /calendar URL.
  def calendar_path_for(start_date, **options)
    date = calendar_start_date_from(start_date)
    options[:start_date] = date.to_s unless date == default_calendar_start_date
    calendar_path(**options)
  end
end
