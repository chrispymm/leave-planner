class MembershipsController < ApplicationController
  before_action :set_membership

  def destroy
    unless Current.user == Current.account.owner
      return redirect_to edit_account_path, alert: "Only the account owner can remove members."
    end

    if @membership.user == Current.account.owner
      return redirect_to edit_account_path, alert: "The account owner cannot be removed."
    end

    @membership.destroy
    redirect_to edit_account_path, notice: "Member removed."
  end

  private
    def set_membership
      @membership = Current.account.memberships.find(params[:id])
    end
end
