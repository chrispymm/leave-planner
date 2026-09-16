class LeaveRangesController < ApplicationController
  before_action :set_person, only: [ :index, :new, :create ]
  before_action :set_leave_range, only: [ :edit, :update, :destroy ]

  def index
    @people = Person.order(:name)
    @selected_person = @person || (params[:person_id].present? ? Person.find_by(id: params[:person_id]) : @people.first)

    if @selected_person
      @leave_ranges = LeaveRange.for_person(@selected_person)
      @year_range = @selected_person.leave_year_range
      @starting_allowance = @selected_person.starting_allowance(@year_range)
      @used_allowance = @selected_person.used_allowance(@year_range)
      @remaining_allowance = @selected_person.remaining_allowance(@year_range)
    else
      @leave_ranges = []
    end
  end

  def new
    @leave_range = LeaveRange.new(
      person: @person,
      person_id: @person.id,
      start_date: Date.current,
      end_date: Date.current,
      half_day: "none"
    )
  end

  def create
    @leave_range = LeaveRange.new(leave_range_params)
    @leave_range.person = @person

    start_date = @leave_range.start_date
    end_date = @leave_range.end_date

    if start_date.blank? || end_date.blank?
      flash.now[:alert] = "Start and End dates are required."
      return render :new, status: :unprocessable_entity
    end

    if end_date < start_date
      end_date = start_date
    end

    ActiveRecord::Base.transaction do
      (start_date..end_date).each do |d|
        next if (start_date != end_date) && (d.saturday? || d.sunday?)

        entry = LeaveEntry.find_or_initialize_by(person: @person, date: d)
        entry.title = @leave_range.title.presence
        entry.half_day = @leave_range.half_day.presence || "none"
        entry.custom_hours = @leave_range.custom_hours.presence
        entry.notes = @leave_range.notes
        entry.save!
      end
    end

    redirect_to person_leave_ranges_path(@person), notice: "Leave range was successfully booked for #{@person.name}."
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = "Error saving leave: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    new_person = Person.find(params[:leave_range][:person_id].presence || @person.id)
    new_title = params[:leave_range][:title].presence
    new_start_date = Date.parse(params[:leave_range][:start_date])
    new_end_date = Date.parse(params[:leave_range][:end_date].presence || params[:leave_range][:start_date])
    new_half_day = params[:leave_range][:half_day].presence || "none"
    new_custom_hours = params[:leave_range][:custom_hours].presence
    new_notes = params[:leave_range][:notes]

    if new_end_date < new_start_date
      new_end_date = new_start_date
    end

    ActiveRecord::Base.transaction do
      # Remove old entries in this specific range
      @entries.each(&:destroy!)

      # Create new entries for updated dates
      (new_start_date..new_end_date).each do |d|
        next if (new_start_date != new_end_date) && (d.saturday? || d.sunday?)

        entry = LeaveEntry.find_or_initialize_by(person: new_person, date: d)
        entry.title = new_title
        entry.half_day = new_half_day
        entry.custom_hours = new_custom_hours
        entry.notes = new_notes
        entry.save!
      end
    end

    redirect_to person_leave_ranges_path(new_person), notice: "Leave range was successfully updated."
  rescue StandardError => e
    flash.now[:alert] = "Error updating leave: #{e.message}"
    render :edit, status: :unprocessable_entity
  end

  def destroy
    person = @person
    count = @entries.size
    @entries.each(&:destroy)

    redirect_to person_leave_ranges_path(person), notice: "Leave range (#{count} #{'day'.pluralize(count)}) was deleted."
  end

  private

  def set_person
    @person = Person.find_by(id: params[:person_id])
  end

  def set_leave_range
    # Format of ID: "first_entry_id-last_entry_id"
    first_id, last_id = params[:id].to_s.split("-")
    first_entry = LeaveEntry.find_by(id: first_id)
    last_entry = LeaveEntry.find_by(id: last_id) || first_entry

    if first_entry.nil? || last_entry.nil? || first_entry.person_id != last_entry.person_id
      redirect_to leave_ranges_path, alert: "Leave range not found."
      return
    end

    @person = first_entry.person
    # Find exact matching range
    all_ranges = LeaveRange.for_person(@person)
    matched_range = all_ranges.find { |r| r.id == params[:id] }

    if matched_range
      @leave_range = matched_range
      @entries = matched_range.entries
    else
      @entries = @person.leave_entries.where(date: first_entry.date..last_entry.date).order(:date).to_a
      @leave_range = LeaveRange.build_range_from_entries(@person, @entries)
    end
  end

  def leave_range_params
    p = params.require(:leave_range).permit(:person_id, :title, :start_date, :end_date, :half_day, :custom_hours, :notes)
    begin
      p[:start_date] = Date.parse(p[:start_date].to_s) if p[:start_date].present?
      p[:end_date] = Date.parse(p[:end_date].to_s) if p[:end_date].present?
    rescue Date::Error
      # Leave invalid strings so validation handles them
    end
    p
  end
end
