class AccountsController < ApplicationController
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

  def account_params
    params.require(:account).permit(:name, :bank_holiday_division)
  end
end
