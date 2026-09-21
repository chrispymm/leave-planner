class InvitationAcceptancesController < ApplicationController
  allow_unauthenticated_access

  before_action :set_invitation

  def show
    redirect_to new_session_path, alert: invalid_invitation_message and return unless @invitation&.pending?
  end

  def create
    unless @invitation&.pending?
      redirect_to new_session_path, alert: invalid_invitation_message and return
    end

    @user = User.new(email_address: @invitation.email, password: params[:password], password_confirmation: params[:password_confirmation])

    created = ActiveRecord::Base.transaction do
      next false unless @user.save

      Membership.create!(user: @user, account: @invitation.account)
      @invitation.update!(accepted_at: Time.current)
      true
    end

    if created
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome! Your account has been created."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def set_invitation
      @invitation = Invitation.find_by(token: params[:token])
    end

    def invalid_invitation_message
      if @invitation.nil?
        "That invitation link is invalid."
      elsif @invitation.accepted?
        "That invitation has already been used. Please sign in instead."
      else
        "That invitation link has expired."
      end
    end
end
