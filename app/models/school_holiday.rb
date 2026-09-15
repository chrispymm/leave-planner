class SchoolHoliday < ApplicationRecord
  validates :title, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  scope :overlapping, ->(start_date, end_date) {
    where("start_date <= ? AND end_date >= ?", end_date, start_date).order(:start_date)
  }

  def self.map_by_date(start_date, end_date)
    # Returns a hash mapping Date -> Array of SchoolHoliday objects
    holidays = overlapping(start_date, end_date)
    mapping = Hash.new { |h, k| h[k] = [] }
    holidays.each do |sh|
      effective_start = [ sh.start_date, start_date ].max
      effective_end = [ sh.end_date, end_date ].min
      (effective_start..effective_end).each do |day|
        mapping[day] << sh
      end
    end
    mapping
  end

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be on or after the start date")
    end
  end
end
