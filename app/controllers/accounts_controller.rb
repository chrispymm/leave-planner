class AccountsController < ApplicationController
  before_action :set_members_and_invitations, only: %i[ edit update ]

  def edit
    @account = Current.account
  end

  def update
    @account = Current.account
    if @account.update(account_params)
      redirect_to edit_account_path, notice: "Settings were successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_members_and_invitations
    @account = Current.account
    @memberships = @account.memberships.includes(:user).order(:id)
    @invitations = @account.invitations.pending.order(:created_at)
  end

  def account_params
    params.require(:account).permit(:name, :bank_holiday_division)
  end
end
