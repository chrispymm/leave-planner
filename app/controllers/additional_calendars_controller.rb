class AdditionalCalendarsController < ApplicationController
  before_action :set_additional_calendar, only: [ :show, :edit, :update, :destroy ]

  def index
    @additional_calendars = Current.account.additional_calendars.alphabetical
      .left_joins(:additional_calendar_entries)
      .select("additional_calendars.*, COUNT(additional_calendar_entries.id) AS entries_count")
      .group("additional_calendars.id")
  end

  def show
    @additional_calendar_entries = @additional_calendar.additional_calendar_entries.order(:start_date)
  end

  def new
    @additional_calendar = Current.account.additional_calendars.new(
      color: AdditionalCalendar::DEFAULT_COLOR
    )
  end

  def edit
  end

  def create
    @additional_calendar = Current.account.additional_calendars.new(additional_calendar_params)

    if @additional_calendar.save
      redirect_to additional_calendar_path(@additional_calendar),
        notice: "#{@additional_calendar.name} was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @additional_calendar.update(additional_calendar_params)
      redirect_to additional_calendar_path(@additional_calendar),
        notice: "#{@additional_calendar.name} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @additional_calendar.destroy
    redirect_to additional_calendars_path, notice: "#{@additional_calendar.name} was deleted."
  end

  private
    def set_additional_calendar
      @additional_calendar = Current.account.additional_calendars.find(params[:id])
    end

    def additional_calendar_params
      params.require(:additional_calendar).permit(:name, :description, :color)
    end
end
