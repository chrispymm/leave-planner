class AdditionalCalendar < ApplicationRecord
  DEFAULT_COLOR = "#f59e0b".freeze

  belongs_to :account
  has_many :additional_calendar_entries, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :account_id, case_sensitive: false }
  validates :color, presence: true, format: {
    with: /\A#(?:\h{3}|\h{6})\z/,
    message: "must be a valid hex colour, for example #f59e0b"
  }

  scope :alphabetical, -> { order(:name) }
end
