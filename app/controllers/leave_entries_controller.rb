class LeaveEntriesController < ApplicationController
  before_action :set_leave_entry, only: [ :update, :destroy ]

  def modal
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @calendar_start_date = calendar_start_date_from(params[:calendar_start_date]).to_s
    @people = Current.account.people.order(:name)

    @existing_entries = LeaveEntry.where(person: @people, date: @date).includes(:person)

    render layout: false
  end

  def toggle
    person = Current.account.people.find(params[:person_id])
    date = Date.parse(params[:date])
    calendar_start = params[:calendar_start_date]

    entry = LeaveEntry.find_by(person: person, date: date)
    if entry
      entry.destroy
    else
      LeaveEntry.create!(person: person, date: date, half_day: "none")
    end

    respond_to do |format|
      format.html { redirect_to calendar_path_for(calendar_start) }
      format.turbo_stream { redirect_to calendar_path_for(calendar_start) }
    end
  end

  def create
    person_ids = Array(params.dig(:leave_entry, :person_ids)).compact_blank
    people = Current.account.people.where(id: person_ids).order(:name).to_a
    if people.empty?
      return redirect_to calendar_path_for(params[:calendar_start_date]), alert: "Select at least one person."
    end

    title = params[:leave_entry][:title].presence
    start_date = Date.parse(params[:leave_entry][:start_date].presence || params[:leave_entry][:date])
    end_date = params[:leave_entry][:end_date].present? ? Date.parse(params[:leave_entry][:end_date]) : start_date
    half_day = params[:leave_entry][:half_day].presence || "none"
    custom_hours = params[:leave_entry][:custom_hours].presence
    notes = params[:leave_entry][:notes]
    calendar_start = params[:calendar_start_date]

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

    redirect_to calendar_path_for(calendar_start), notice: "Leave updated for #{people.map(&:name).to_sentence}."
  end

  def update
    calendar_start = params[:calendar_start_date]
    @leave_entry.update(leave_entry_params)
    redirect_to calendar_path_for(calendar_start), notice: "Leave updated."
  end

  def destroy
    calendar_start = params[:calendar_start_date]
    @leave_entry.destroy
    redirect_to calendar_path_for(calendar_start), notice: "Leave entry removed."
  end

  private

  def set_leave_entry
    @leave_entry = LeaveEntry.where(person: Current.account.people).find(params[:id])
  end

  def leave_entry_params
    params.require(:leave_entry).permit(:person_id, :title, :date, :half_day, :custom_hours, :notes)
  end
end
