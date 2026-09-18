class Account < ApplicationRecord
  BANK_HOLIDAY_DIVISIONS = %w[england-and-wales scotland northern-ireland].freeze

  belongs_to :owner, class_name: "User"
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :people, dependent: :destroy
  has_many :school_holidays, dependent: :destroy

  validates :name, presence: true
  validates :bank_holiday_division, inclusion: { in: BANK_HOLIDAY_DIVISIONS }
end
