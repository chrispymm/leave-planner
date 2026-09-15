class BankHoliday < ApplicationRecord
  validates :title, presence: true
  validates :date, presence: true
  validates :division, presence: true
  validates :date, uniqueness: { scope: :division, message: "already exists for this division" }

  scope :between, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :for_division, ->(division = "england-and-wales") { where(division: division) }

  def self.dates_set(start_date, end_date, division = "england-and-wales")
    between(start_date, end_date).for_division(division).pluck(:date).to_set
  end

  def self.map_by_date(start_date, end_date, division = "england-and-wales")
    between(start_date, end_date).for_division(division).index_by(&:date)
  end
end
