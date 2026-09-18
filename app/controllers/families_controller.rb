class FamiliesController < ApplicationController
  def edit
    @family = Current.family
  end

  def update
    @family = Current.family
    if @family.update(family_params)
      redirect_to edit_family_path, notice: "Settings were successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def family_params
    params.require(:family).permit(:name, :bank_holiday_division)
  end
end
