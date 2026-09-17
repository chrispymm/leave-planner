class LeaveEntriesController < ApplicationController
  before_action :set_leave_entry, only: [ :update, :destroy ]

  def modal
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @calendar_start_date = params[:calendar_start_date].presence || Date.current.beginning_of_month.to_s
    @layout = params[:layout] == "list" ? "list" : "grid"
    @people = Person.order(:name)

    @existing_entries = LeaveEntry.where(date: @date).includes(:person)

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
      format.html { redirect_to calendar_path(start_date: calendar_start, **calendar_layout_params) }
      format.turbo_stream { redirect_to calendar_path(start_date: calendar_start, **calendar_layout_params) }
    end
  end

  def create
    person_ids = Array(params.dig(:leave_entry, :person_ids)).compact_blank
    people = Person.where(id: person_ids).order(:name).to_a
    if people.empty?
      return redirect_to calendar_path(start_date: params[:calendar_start_date], **calendar_layout_params), alert: "Select at least one person."
    end

    title = params[:leave_entry][:title].presence
    start_date = Date.parse(params[:leave_entry][:start_date].presence || params[:leave_entry][:date])
    end_date = params[:leave_entry][:end_date].present? ? Date.parse(params[:leave_entry][:end_date]) : start_date
    half_day = params[:leave_entry][:half_day].presence || "none"
    custom_hours = params[:leave_entry][:custom_hours].presence
    notes = params[:leave_entry][:notes]
    calendar_start = params[:calendar_start_date].presence || Date.current.beginning_of_month.to_s

    if end_date < start_date
      end_date = start_date
    end

    ActiveRecord::Base.transaction do
      people.each do |person|
        (start_date..end_date).each do |d|
          next if (start_date != end_date) && (d.saturday? || d.sunday?)

          entry = LeaveEntry.find_or_initialize_by(person: person, date: d)
          entry.title = title
          entry.half_day = half_day
          entry.custom_hours = custom_hours
          entry.notes = notes
          entry.save!
        end
      end
    end

    redirect_to calendar_path(start_date: calendar_start, **calendar_layout_params), notice: "Leave updated for #{people.map(&:name).to_sentence}."
  end

  def update
    calendar_start = params[:calendar_start_date].presence || Date.current.beginning_of_month.to_s
    @leave_entry.update(leave_entry_params)
    redirect_to calendar_path(start_date: calendar_start, **calendar_layout_params), notice: "Leave updated."
  end

  def destroy
    calendar_start = params[:calendar_start_date].presence || Date.current.beginning_of_month.to_s
    @leave_entry.destroy
    redirect_to calendar_path(start_date: calendar_start, **calendar_layout_params), notice: "Leave entry removed."
  end

  private

  def calendar_layout_params
    params[:layout] == "list" ? { layout: "list" } : {}
  end

  def set_leave_entry
    @leave_entry = LeaveEntry.find(params[:id])
  end

  def leave_entry_params
    params.require(:leave_entry).permit(:person_id, :title, :date, :half_day, :custom_hours, :notes)
  end
end
