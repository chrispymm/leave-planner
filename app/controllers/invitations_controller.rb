class InvitationsController < ApplicationController
  before_action :set_invitation, only: :destroy

  def new
    @invitation = Current.account.invitations.new
  end

  def create
    @invitation = Current.account.invitations.new(invitation_params)
    @invitation.invited_by = Current.user

    if @invitation.save
      flash[:invite_link] = accept_invitation_url(@invitation.token)
      redirect_to edit_account_path, notice: "Invitation created for #{@invitation.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @invitation.destroy
    redirect_to edit_account_path, notice: "Invitation cancelled."
  end

  private
    def set_invitation
      @invitation = Current.account.invitations.find(params[:id])
    end

    def invitation_params
      params.require(:invitation).permit(:email)
    end
end
