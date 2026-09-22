class AdditionalCalendarEntriesController < ApplicationController
  before_action :set_additional_calendar, only: [ :new, :create ]
  before_action :set_additional_calendar_entry, only: [ :edit, :update, :destroy ]

  def new
    @additional_calendar_entry = @additional_calendar.additional_calendar_entries.new(
      start_date: Date.current,
      end_date: Date.current + 7.days
    )
  end

  def edit
  end

  def create
    @additional_calendar_entry = @additional_calendar.additional_calendar_entries.new(
      additional_calendar_entry_params
    )

    if @additional_calendar_entry.save
      redirect_to additional_calendar_path(@additional_calendar),
        notice: "#{@additional_calendar_entry.title} was added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @additional_calendar_entry.update(additional_calendar_entry_params)
      redirect_to additional_calendar_path(@additional_calendar_entry.additional_calendar),
        notice: "#{@additional_calendar_entry.title} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    calendar = @additional_calendar_entry.additional_calendar
    @additional_calendar_entry.destroy

    redirect_to additional_calendar_path(calendar),
      notice: "#{@additional_calendar_entry.title} was removed."
  end

  private
    def set_additional_calendar
      @additional_calendar = Current.account.additional_calendars.find(params[:additional_calendar_id])
    end

    # Scoped through the account's calendars so entries belonging to another
    # account are never reachable by guessing an id.
    def set_additional_calendar_entry
      @additional_calendar_entry = AdditionalCalendarEntry
        .where(additional_calendar: Current.account.additional_calendars)
        .find(params[:id])
      @additional_calendar = @additional_calendar_entry.additional_calendar
    end

    def additional_calendar_entry_params
      params.require(:additional_calendar_entry).permit(:title, :start_date, :end_date, :notes)
    end
end
