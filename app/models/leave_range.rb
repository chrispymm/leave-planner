class LeaveRange
  include ActiveModel::Model

  attr_accessor :id, :person, :person_id, :person_ids, :title, :start_date, :end_date, :half_day, :custom_hours, :notes, :entries, :cost_days, :cost_hours

  def self.for_person(person)
    entries = person.leave_entries.order(:date).to_a
    return [] if entries.empty?

    ranges = []
    current_entries = [ entries.first ]

    entries.drop(1).each do |entry|
      prev_entry = current_entries.last

      # Check if entry is consecutive or contiguous across a weekend
      days_diff = (entry.date - prev_entry.date).to_i
      is_contiguous = if days_diff == 1
                        true
      elsif days_diff <= 3 && prev_entry.date.friday? && entry.date.monday?
                        true
      else
                        false
      end

      # Check if characteristics match (title, half_day, custom_hours, notes)
      same_attributes = (entry.title == prev_entry.title) &&
                        (entry.half_day == prev_entry.half_day) &&
                        (entry.custom_hours == prev_entry.custom_hours) &&
                        (entry.notes == prev_entry.notes)

      if is_contiguous && same_attributes
        current_entries << entry
      else
        ranges << build_range_from_entries(person, current_entries)
        current_entries = [ entry ]
      end
    end

    ranges << build_range_from_entries(person, current_entries) if current_entries.any?
    ranges
  end

  def self.build_range_from_entries(person, entries)
    first_entry = entries.first
    last_entry = entries.last
    range_id = "#{first_entry.id}-#{last_entry.id}"

    bh_set = BankHoliday.dates_set(first_entry.date, last_entry.date)
    total_cost_days = entries.sum { |e| e.cost_in_days(bh_set, person: person) }
    total_cost_hours = entries.sum { |e| e.cost_in_hours(bh_set, person: person) }

    new(
      id: range_id,
      person: person,
      person_id: person.id,
      title: first_entry.title,
      start_date: first_entry.date,
      end_date: last_entry.date,
      half_day: first_entry.half_day,
      custom_hours: first_entry.custom_hours,
      notes: first_entry.notes,
      entries: entries,
      cost_days: total_cost_days.round(2),
      cost_hours: total_cost_hours.round(2)
    )
  end

  def persisted?
    id.present?
  end

  def to_key
    id ? [ id ] : nil
  end

  def to_param
    id
  end

  def display_title
    return title if title.present?

    formatted_dates
  end

  def formatted_dates
    if start_date == end_date
      start_date.strftime("%a, %-d %b %Y")
    else
      "#{start_date.strftime('%a, %-d %b %Y')} – #{end_date.strftime('%a, %-d %b %Y')}"
    end
  end

  def duration_days
    (end_date - start_date).to_i + 1
  end

  def working_days_count
    entries&.count || 0
  end

  def half_day?
    %w[morning afternoon].include?(half_day)
  end

  def duration_display
    if person.in_hours?
      "#{person.format_amount(cost_hours)} hrs"
    else
      "#{person.format_amount(cost_days)} days"
    end
  end

  def type_display
    if custom_hours.present? && custom_hours.to_f > 0
      "#{person.format_amount(custom_hours)} hrs / day"
    elsif half_day?
      "#{half_day.capitalize} (0.5 day)"
    else
      "Full Day"
    end
  end
end
