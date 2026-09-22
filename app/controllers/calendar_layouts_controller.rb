class CalendarLayoutsController < ApplicationController
  def update
    if Current.user.update(calendar_layout: calendar_layout_params[:layout])
      redirect_to calendar_path_for(calendar_layout_params[:start_date]), status: :see_other
    else
      redirect_to calendar_path_for(calendar_layout_params[:start_date]),
        alert: "Calendar layout could not be updated.",
        status: :see_other
    end
  end

  private
    def calendar_layout_params
      params.require(:calendar_layout).permit(:layout, :start_date)
    end
end
