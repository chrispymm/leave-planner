class LeaveEntriesController < ApplicationController
  before_action :set_leave_entry, only: [ :update, :destroy ]

  def modal
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @calendar_start_date = params[:calendar_start_date].presence || Date.current.beginning_of_month.to_s
    @people = Person.order(:name)
    @selected_person = Person.find_by(id: params[:person_id]) || @people.first

    @existing_entries = LeaveEntry.where(date: @date).includes(:person)
    @active_entry = @existing_entries.find { |e| e.person_id == @selected_person&.id }

    render layout: false
  end

  def toggle
    person = Person.find(params[:person_id])
    date = Date.parse(params[:date])
    calendar_start = params[:calendar_start_date].presence || Date.current.beginning_of_month.to_s

    entry = LeaveEntry.find_by(person: person, date: date)
    if entry
      entry.destroy
    else
      LeaveEntry.create!(person: person, date: date, half_day: "none")
    end

    respond_to do |format|
      format.html { redirect_to calendar_path(start_date: calendar_start, person_id: person.id) }
      format.turbo_stream { redirect_to calendar_path(start_date: calendar_start, person_id: person.id) }
    end
  end

  def create
    person = Person.find(params[:leave_entry][:person_id])
    start_date = Date.parse(params[:leave_entry][:start_date].presence || params[:leave_entry][:date])
    end_date = params[:leave_entry][:end_date].present? ? Date.parse(params[:leave_entry][:end_date]) : start_date
    half_day = params[:leave_entry][:half_day].presence || "none"
    custom_hours = params[:leave_entry][:custom_hours].presence
    notes = params[:leave_entry][:notes]
    calendar_start = params[:calendar_start_date].presence || Date.current.beginning_of_month.to_s

    if end_date < start_date
      end_date = start_date
    end

    # Create entries for each day in range
    (start_date..end_date).each do |d|
      # Skip weekends for bulk bookings unless specifically desired
      next if (start_date != end_date) && (d.saturday? || d.sunday?)

      entry = LeaveEntry.find_or_initialize_by(person: person, date: d)
      entry.half_day = half_day
      entry.custom_hours = custom_hours
      entry.notes = notes
      entry.save
    end

    redirect_to calendar_path(start_date: calendar_start, person_id: person.id), notice: "Leave updated for #{person.name}."
  end

  def update
    calendar_start = params[:calendar_start_date].presence || Date.current.beginning_of_month.to_s
    @leave_entry.update(leave_entry_params)
    redirect_to calendar_path(start_date: calendar_start, person_id: @leave_entry.person_id), notice: "Leave updated."
  end

  def destroy
    person_id = @leave_entry.person_id
    calendar_start = params[:calendar_start_date].presence || Date.current.beginning_of_month.to_s
    @leave_entry.destroy
    redirect_to calendar_path(start_date: calendar_start, person_id: person_id), notice: "Leave entry removed."
  end

  private

  def set_leave_entry
    @leave_entry = LeaveEntry.find(params[:id])
  end

  def leave_entry_params
    params.require(:leave_entry).permit(:person_id, :date, :half_day, :custom_hours, :notes)
  end
end
