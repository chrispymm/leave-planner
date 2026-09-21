class Invitation < ApplicationRecord
  has_secure_token :token

  belongs_to :account
  belongs_to :invited_by, class_name: "User"

  before_validation :set_expiry, on: :create

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :email_not_already_a_user, on: :create
  validate :no_duplicate_pending_invitation, on: :create

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }

  def expired?
    expires_at.past?
  end

  def accepted?
    accepted_at.present?
  end

  def pending?
    !accepted? && !expired?
  end

  private
    def set_expiry
      self.expires_at ||= 48.hours.from_now
    end

    def email_not_already_a_user
      return if email.blank?

      if User.exists?(email_address: email.to_s.strip.downcase)
        errors.add(:email, "already has an account")
      end
    end

    def no_duplicate_pending_invitation
      return if email.blank? || account.blank?

      if account.invitations.pending.where(email: email).exists?
        errors.add(:email, "already has a pending invitation")
      end
    end
end
