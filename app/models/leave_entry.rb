class LeaveEntry < ApplicationRecord
  belongs_to :person

  validates :date, presence: true
  validates :date, uniqueness: { scope: :person_id, message: "already has a leave entry on this date" }
  validates :half_day, inclusion: { in: %w[none morning afternoon] }
  validates :custom_hours, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  scope :for_period, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :on_date, ->(date) { where(date: date) }

  def weekend?
    date.saturday? || date.sunday?
  end

  # These check only the immediate neighbour (with a Fri/Mon weekend bridge)
  # via indexed lookups, rather than rebuilding the person's full range list.
  def first_in_range?
    !contiguous_neighbour(:before)
  end

  def last_in_range?
    !contiguous_neighbour(:after)
  end

  def half_day?
    %w[morning afternoon].include?(half_day)
  end

  def free_bank_holiday?(bank_holidays_set = nil, person_obj = nil)
    target_person = person_obj || person
    return false if target_person.include_bank_holidays

    bh_set = bank_holidays_set || BankHoliday.dates_set(date, date)
    bh_set.include?(date)
  end

  def cost_in_days(bank_holidays_set = nil, person: nil)
    return 0.0 if weekend?
    return 0.0 if free_bank_holiday?(bank_holidays_set, person)

    target_person = person || self.person
    h_per_day = target_person.hours_per_day.to_f
    h_per_day = 7.5 if h_per_day <= 0

    if custom_hours.present? && custom_hours.to_f > 0
      (custom_hours.to_f / h_per_day).round(3)
    elsif half_day?
      0.5
    else
      1.0
    end
  end

  def cost_in_hours(bank_holidays_set = nil, person: nil)
    return 0.0 if weekend?
    return 0.0 if free_bank_holiday?(bank_holidays_set, person)

    target_person = person || self.person
    h_per_day = target_person.hours_per_day.to_f
    h_per_day = 7.5 if h_per_day <= 0

    if custom_hours.present? && custom_hours.to_f > 0
      custom_hours.to_f
    elsif half_day?
      (h_per_day / 2.0).round(2)
    else
      h_per_day
    end
  end

  private

  # Finds the adjacent LeaveEntry (previous day for :before, next day for
  # :after), bridging a weekend between Friday and Monday, and returns it
  # only if LeaveRange.contiguous? considers the pair part of the same range.
  def contiguous_neighbour(direction)
    candidate_date = direction == :before ? date - 1 : date + 1
    candidate = person.leave_entries.find_by(date: candidate_date)

    if candidate.nil?
      if direction == :before && date.monday?
        candidate = person.leave_entries.find_by(date: date - 3) # preceding Friday
      elsif direction == :after && date.friday?
        candidate = person.leave_entries.find_by(date: date + 3) # following Monday
      end
    end

    return nil unless candidate

    earlier_entry, later_entry = direction == :before ? [ candidate, self ] : [ self, candidate ]
    LeaveRange.contiguous?(earlier_entry, later_entry) ? candidate : nil
  end
end
