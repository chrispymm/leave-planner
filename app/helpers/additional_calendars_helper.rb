module AdditionalCalendarsHelper
  MAX_CALENDAR_BANDS = 3

  # Colours are interpolated into inline style attributes, so anything that is
  # not a plain hex colour is rejected rather than rendered. Model validation
  # already enforces this on write, but rows can predate the validation (the
  # migrated school_holidays colours were never validated), so the render side
  # refuses to trust the stored value.
  def safe_calendar_color(color)
    color.to_s.match?(/\A#(?:\h{3}|\h{6})\z/) ? color : AdditionalCalendar::DEFAULT_COLOR
  end

  def calendar_color_swatch(color, size: "1.25rem")
    tag.span(
      "",
      style: "display: inline-block; width: #{size}; height: #{size}; border-radius: 4px; " \
             "background-color: #{safe_calendar_color(color)}; border: 1px solid rgba(0, 0, 0, 0.2);"
    )
  end

  # Stacked bottom bands, one per distinct calendar colour. Earlier bands are
  # listed first so they paint on top, stacking upwards from the bottom edge.
  def additional_calendar_band_style(entries)
    colors = Array(entries).map { |entry| safe_calendar_color(entry.calendar_color) }
                           .uniq.first(MAX_CALENDAR_BANDS)
    return nil if colors.empty?

    shadows = colors.each_with_index.map do |color, index|
      "inset 0 -#{3 * (index + 1)}px 0 0 #{color}"
    end

    "box-shadow: #{shadows.join(', ')};"
  end
end
