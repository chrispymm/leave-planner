class AdditionalCalendarEntry < ApplicationRecord
  belongs_to :additional_calendar

  has_one :account, through: :additional_calendar

  validates :title, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  scope :overlapping, ->(start_date, end_date) {
    where("start_date <= ? AND end_date >= ?", end_date, start_date).order(:start_date)
  }

  delegate :color, :name, to: :additional_calendar, prefix: :calendar

  # Returns a hash mapping Date -> Array of AdditionalCalendarEntry objects.
  def self.map_by_date(start_date, end_date)
    entries = overlapping(start_date, end_date).includes(:additional_calendar)

    entries.each_with_object(Hash.new { |h, k| h[k] = [] }) do |entry, mapping|
      effective_start = [ entry.start_date, start_date ].max
      effective_end = [ entry.end_date, end_date ].min

      (effective_start..effective_end).each { |day| mapping[day] << entry }
    end
  end

  def duration_in_days
    return 0 if start_date.blank? || end_date.blank?

    (end_date - start_date).to_i + 1
  end

  private
    def end_date_after_start_date
      return if start_date.blank? || end_date.blank?

      errors.add(:end_date, "must be on or after the start date") if end_date < start_date
    end
end
