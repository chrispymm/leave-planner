class Person < ApplicationRecord
  has_many :leave_entries, dependent: :destroy

  before_validation :set_default_initial_allowance_date

  validates :name, presence: true
  validates :color, presence: true
  validates :allowance_unit, inclusion: { in: %w[days hours] }
  validates :allowance_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :initial_remaining_allowance, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :hours_per_day, numericality: { greater_than: 0 }
  validates :leave_year_start_month, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :leave_year_start_day, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 31 }
  validate :valid_leave_year_start_date

  def in_days?
    allowance_unit == "days"
  end

  def in_hours?
    allowance_unit == "hours"
  end

  def leave_year_start_day_formatted
    month = leave_year_start_month || 1
    day = leave_year_start_day || 1
    "#{day.ordinalize} #{Date::MONTHNAMES[month]}"
  end

  def leave_year_range(reference_date = Date.current)
    start_month = leave_year_start_month || 1
    start_day = leave_year_start_day || 1
    ref_year = reference_date.year

    start_date = safe_date(ref_year, start_month, start_day)
    start_date = if reference_date >= start_date
                   start_date
    else
                   safe_date(ref_year - 1, start_month, start_day)
    end
    end_date = (start_date + 1.year) - 1.day

    start_date..end_date
  end

  def leave_entries_for_year(reference_date = Date.current)
    range = leave_year_range(reference_date)
    leave_entries.where(date: range)
  end

  def initial_allowance_active_for?(range_or_ref_date = Date.current)
    return false if initial_remaining_allowance.nil? || initial_allowance_date.blank?

    ref_date = range_or_ref_date.is_a?(Range) ? range_or_ref_date.begin : range_or_ref_date
    current_year_range = leave_year_range(ref_date)
    current_year_range.cover?(initial_allowance_date)
  end

  def starting_allowance(range_or_ref_date = Date.current)
    if initial_allowance_active_for?(range_or_ref_date)
      initial_remaining_allowance.to_f
    else
      allowance_amount.to_f
    end
  end

  def used_allowance(range_or_ref_date = Date.current, bank_holidays_set: nil)
    range = range_or_ref_date.is_a?(Range) ? range_or_ref_date : leave_year_range(range_or_ref_date)

    effective_start = if initial_allowance_active_for?(range)
                        [ range.begin, initial_allowance_date ].max
    else
                        range.begin
    end

    return 0.0 if effective_start > range.end

    entries = leave_entries.where(date: effective_start..range.end)

    bh_set = bank_holidays_set || (include_bank_holidays ? Set.new : BankHoliday.dates_set(effective_start, range.end))

    total = 0.0
    entries.each do |entry|
      total += in_hours? ? entry.cost_in_hours(bh_set, person: self) : entry.cost_in_days(bh_set, person: self)
    end
    total
  end

  def remaining_allowance(range_or_ref_date = Date.current, bank_holidays_set: nil)
    (starting_allowance(range_or_ref_date) - used_allowance(range_or_ref_date, bank_holidays_set: bank_holidays_set)).round(2)
  end

  def format_amount(val)
    val = val.to_f
    val == val.to_i ? val.to_i.to_s : sprintf("%.1f", val)
  end

  private

  def set_default_initial_allowance_date
    if initial_remaining_allowance.present? && initial_allowance_date.blank?
      self.initial_allowance_date = Date.current
    end
  end

  def safe_date(year, month, day)
    # Handle end-of-month dates like Feb 29/30/31
    max_days = Time.days_in_month(month, year)
    Date.new(year, month, [ day, max_days ].min)
  end

  def valid_leave_year_start_date
    return if leave_year_start_month.blank? || leave_year_start_day.blank?

    # Check for leap year neutral validity (using 2024 as leap year)
    max_days = Time.days_in_month(leave_year_start_month, 2024)
    if leave_year_start_day > max_days
      errors.add(:leave_year_start_day, "is not a valid day for #{Date::MONTHNAMES[leave_year_start_month]}")
    end
  end
end
