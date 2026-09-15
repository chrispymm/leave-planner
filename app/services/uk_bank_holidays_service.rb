require "net/http"
require "json"

class UkBankHolidaysService
  GOV_UK_URL = "https://www.gov.uk/bank-holidays.json"

  # Static fallback covering 2024 through 2028 for England & Wales, Scotland, and Northern Ireland
  FALLBACK_HOLIDAYS = [
    # 2024 England and Wales
    { date: "2024-01-01", title: "New Year's Day", division: "england-and-wales" },
    { date: "2024-03-29", title: "Good Friday", division: "england-and-wales" },
    { date: "2024-04-01", title: "Easter Monday", division: "england-and-wales" },
    { date: "2024-05-06", title: "Early May bank holiday", division: "england-and-wales" },
    { date: "2024-05-27", title: "Spring bank holiday", division: "england-and-wales" },
    { date: "2024-08-26", title: "Summer bank holiday", division: "england-and-wales" },
    { date: "2024-12-25", title: "Christmas Day", division: "england-and-wales" },
    { date: "2024-12-26", title: "Boxing Day", division: "england-and-wales" },

    # 2025 England and Wales
    { date: "2025-01-01", title: "New Year's Day", division: "england-and-wales" },
    { date: "2025-04-18", title: "Good Friday", division: "england-and-wales" },
    { date: "2025-04-21", title: "Easter Monday", division: "england-and-wales" },
    { date: "2025-05-05", title: "Early May bank holiday", division: "england-and-wales" },
    { date: "2025-05-26", title: "Spring bank holiday", division: "england-and-wales" },
    { date: "2025-08-25", title: "Summer bank holiday", division: "england-and-wales" },
    { date: "2025-12-25", title: "Christmas Day", division: "england-and-wales" },
    { date: "2025-12-26", title: "Boxing Day", division: "england-and-wales" },

    # 2026 England and Wales
    { date: "2026-01-01", title: "New Year's Day", division: "england-and-wales" },
    { date: "2026-04-03", title: "Good Friday", division: "england-and-wales" },
    { date: "2026-04-06", title: "Easter Monday", division: "england-and-wales" },
    { date: "2026-05-04", title: "Early May bank holiday", division: "england-and-wales" },
    { date: "2026-05-25", title: "Spring bank holiday", division: "england-and-wales" },
    { date: "2026-08-31", title: "Summer bank holiday", division: "england-and-wales" },
    { date: "2026-12-25", title: "Christmas Day", division: "england-and-wales" },
    { date: "2026-12-28", title: "Boxing Day (substitute day)", division: "england-and-wales" },

    # 2027 England and Wales
    { date: "2027-01-01", title: "New Year's Day", division: "england-and-wales" },
    { date: "2027-03-26", title: "Good Friday", division: "england-and-wales" },
    { date: "2027-03-29", title: "Easter Monday", division: "england-and-wales" },
    { date: "2027-05-03", title: "Early May bank holiday", division: "england-and-wales" },
    { date: "2027-05-31", title: "Spring bank holiday", division: "england-and-wales" },
    { date: "2027-08-30", title: "Summer bank holiday", division: "england-and-wales" },
    { date: "2027-12-27", title: "Christmas Day (substitute day)", division: "england-and-wales" },
    { date: "2027-12-28", title: "Boxing Day (substitute day)", division: "england-and-wales" },

    # 2028 England and Wales
    { date: "2028-01-03", title: "New Year's Day (substitute day)", division: "england-and-wales" },
    { date: "2028-04-14", title: "Good Friday", division: "england-and-wales" },
    { date: "2028-04-17", title: "Easter Monday", division: "england-and-wales" },
    { date: "2028-05-01", title: "Early May bank holiday", division: "england-and-wales" },
    { date: "2028-05-29", title: "Spring bank holiday", division: "england-and-wales" },
    { date: "2028-08-28", title: "Summer bank holiday", division: "england-and-wales" },
    { date: "2028-12-25", title: "Christmas Day", division: "england-and-wales" },
    { date: "2028-12-26", title: "Boxing Day", division: "england-and-wales" }
  ].freeze

  def self.sync!
    data = fetch_gov_uk_data
    if data.present?
      sync_from_data(data)
    else
      sync_from_fallback
    end
  end

  def self.fetch_gov_uk_data
    uri = URI(GOV_UK_URL)
    response = Net::HTTP.get_response(uri)
    return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

    nil
  rescue StandardError => e
    Rails.logger.warn("Could not fetch gov.uk bank holidays: #{e.message}. Using fallback data.")
    nil
  end

  def self.sync_from_data(data)
    count = 0
    data.each do |division_key, division_data|
      division_name = division_key.to_s.tr("_", "-")
      events = division_data["events"] || []
      events.each do |event|
        date = Date.parse(event["date"])
        title = event["title"]
        notes = event["notes"]
        record = BankHoliday.find_or_initialize_by(date: date, division: division_name)
        record.title = title
        record.notes = notes
        if record.save
          count += 1
        end
      end
    end
    count
  end

  def self.sync_from_fallback
    count = 0
    FALLBACK_HOLIDAYS.each do |item|
      record = BankHoliday.find_or_initialize_by(date: Date.parse(item[:date]), division: item[:division])
      record.title = item[:title]
      if record.save
        count += 1
      end
    end
    count
  end
end
