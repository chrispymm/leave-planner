class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :accounts, through: :memberships
  has_many :owned_accounts, class_name: "Account", foreign_key: :owner_id, dependent: :restrict_with_error

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # For now each user belongs to exactly one account (assigned at seed/creation
  # time). If multi-account support is needed later, replace this with an
  # explicit account switcher.
  def account
    accounts.first
  end
end
