# Seed UK Bank Holidays
puts "Seeding UK Bank Holidays..."
UkBankHolidaysService.sync!
puts "Bank holidays count: #{BankHoliday.count}"

# Seed default people if none exist
if Person.none?
  puts "Creating initial people..."
  Person.create!(
    name: "Chris",
    color: "#2563eb", # Blue
    allowance_unit: "days",
    allowance_amount: 25.0,
    hours_per_day: 7.5,
    include_bank_holidays: false,
    leave_year_start_month: 1,
    leave_year_start_day: 1
  )

  Person.create!(
    name: "Wife",
    color: "#db2777", # Pink / Rose
    allowance_unit: "days",
    allowance_amount: 25.0,
    hours_per_day: 7.5,
    include_bank_holidays: false,
    leave_year_start_month: 1,
    leave_year_start_day: 1
  )
end

# Seed typical UK School Holidays if none exist
if SchoolHoliday.none?
  puts "Creating sample UK school holidays..."
  current_year = Date.current.year
  [ current_year, current_year + 1 ].each do |year|
    SchoolHoliday.create!(
      title: "February Half Term #{year}",
      start_date: Date.new(year, 2, 16),
      end_date: Date.new(year, 2, 20),
      color: "#f59e0b"
    )

    SchoolHoliday.create!(
      title: "Easter Holidays #{year}",
      start_date: Date.new(year, 3, 30),
      end_date: Date.new(year, 4, 10),
      color: "#f59e0b"
    )

    SchoolHoliday.create!(
      title: "May Half Term #{year}",
      start_date: Date.new(year, 5, 25),
      end_date: Date.new(year, 5, 29),
      color: "#f59e0b"
    )

    SchoolHoliday.create!(
      title: "Summer Holidays #{year}",
      start_date: Date.new(year, 7, 23),
      end_date: Date.new(year, 9, 2),
      color: "#f59e0b"
    )

    SchoolHoliday.create!(
      title: "October Half Term #{year}",
      start_date: Date.new(year, 10, 26),
      end_date: Date.new(year, 10, 30),
      color: "#f59e0b"
    )

    SchoolHoliday.create!(
      title: "Christmas Holidays #{year}",
      start_date: Date.new(year, 12, 21),
      end_date: Date.new(year + 1, 1, 1),
      color: "#f59e0b"
    )
  end
end
