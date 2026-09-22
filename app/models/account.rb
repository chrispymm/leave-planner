class Account < ApplicationRecord
  BANK_HOLIDAY_DIVISIONS = %w[england-and-wales scotland northern-ireland].freeze

  belongs_to :owner, class_name: "User"
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :people, dependent: :destroy
  has_many :additional_calendars, dependent: :destroy
  has_many :additional_calendar_entries, through: :additional_calendars
  has_many :invitations, dependent: :destroy

  validates :name, presence: true
  validates :bank_holiday_division, inclusion: { in: BANK_HOLIDAY_DIVISIONS }
end
