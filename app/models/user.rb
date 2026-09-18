class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :families, through: :memberships
  has_many :owned_families, class_name: "Family", foreign_key: :owner_id, dependent: :restrict_with_error

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # For now each user belongs to exactly one family (assigned at seed/creation
  # time). If multi-family support is needed later, replace this with an
  # explicit family switcher.
  def family
    families.first
  end
end
