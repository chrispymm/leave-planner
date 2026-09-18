class LeaveRangesController < ApplicationController
  before_action :set_person, only: [ :index, :new, :create ]
  before_action :set_leave_range, only: [ :edit, :update, :destroy ]

  def index
    @people = Current.account.people.order(:name)
    @selected_person = @person || (params[:person_id].present? ? @people.find_by(id: params[:person_id]) : @people.first)

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
    @people = Current.account.people.order(:name)
    @leave_range = LeaveRange.new(
      person: @person,
      person_id: @person.id,
      person_ids: [ @person.id.to_s ],
      start_date: Date.current,
      end_date: Date.current,
      half_day: "none"
    )
  end

  def create
    @leave_range = LeaveRange.new(leave_range_params)
    @people = Current.account.people.order(:name)
    submitted_person_ids = params.dig(:leave_range, :person_ids)
    person_ids = if submitted_person_ids.nil?
      [ params.dig(:leave_range, :person_id).presence || @person&.id ].compact
    else
      Array(submitted_person_ids).compact_blank
    end
    selected_people = Current.account.people.where(id: person_ids).order(:name).to_a
    @leave_range.person_ids = person_ids
    @leave_range.person = selected_people.first

    start_date = @leave_range.start_date
    end_date = @leave_range.end_date

    if selected_people.empty?
      flash.now[:alert] = "Select at least one person."
      return render :new, status: :unprocessable_entity
    end

    if start_date.blank? || end_date.blank?
      flash.now[:alert] = "Start and End dates are required."
      return render :new, status: :unprocessable_entity
    end

    if end_date < start_date
      end_date = start_date
    end

    ActiveRecord::Base.transaction do
      selected_people.each do |person|
        (start_date..end_date).each do |d|
          next if (start_date != end_date) && (d.saturday? || d.sunday?)

          entry = LeaveEntry.find_or_initialize_by(person: person, date: d)
          entry.title = @leave_range.title.presence
          entry.half_day = @leave_range.half_day.presence || "none"
          entry.custom_hours = @leave_range.custom_hours.presence
          entry.notes = @leave_range.notes
          entry.save!
        end
      end
    end

    redirect_to person_leave_ranges_path(@person || selected_people.first), notice: "Leave range was successfully booked for #{selected_people.map(&:name).to_sentence}."
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = "Error saving leave: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    submitted_person_ids = params.dig(:leave_range, :person_ids)
    person_ids = if submitted_person_ids.nil?
      [ params.dig(:leave_range, :person_id).presence || @person.id ].compact
    else
      Array(submitted_person_ids).compact_blank
    end
    selected_people = Current.account.people.where(id: person_ids).order(:name).to_a
    @leave_range.person_ids = person_ids

    if selected_people.empty?
      flash.now[:alert] = "Select at least one person."
      return render :edit, status: :unprocessable_entity
    end

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
      @entries.each(&:destroy!)

      selected_people.each do |person|
        (new_start_date..new_end_date).each do |d|
          next if (new_start_date != new_end_date) && (d.saturday? || d.sunday?)

          entry = LeaveEntry.find_or_initialize_by(person: person, date: d)
          entry.title = new_title
          entry.half_day = new_half_day
          entry.custom_hours = new_custom_hours
          entry.notes = new_notes
          entry.save!
        end
      end
    end

    redirect_to person_leave_ranges_path(@person), notice: "Leave range was successfully updated for #{selected_people.map(&:name).to_sentence}."
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
    @person = Current.account.people.find_by(id: params[:person_id])
  end

  def set_leave_range
    # Format of ID: "first_entry_id-last_entry_id"
    first_id, last_id = params[:id].to_s.split("-")
    scoped_entries = LeaveEntry.where(person: Current.account.people)
    first_entry = scoped_entries.find_by(id: first_id)
    last_entry = scoped_entries.find_by(id: last_id) || first_entry

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

    @people = Current.account.people.order(:name)
    @leave_range.person_ids = [ @person.id.to_s ]
  end

  def leave_range_params
    p = params.require(:leave_range).permit(:person_id, :title, :start_date, :end_date, :half_day, :custom_hours, :notes, person_ids: [])
    begin
      p[:start_date] = Date.parse(p[:start_date].to_s) if p[:start_date].present?
      p[:end_date] = Date.parse(p[:end_date].to_s) if p[:end_date].present?
    rescue Date::Error
      # Leave invalid strings so validation handles them
    end
    p
  end
end
