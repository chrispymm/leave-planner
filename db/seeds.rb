# Seed a default User + Family so there is somewhere to log in.
# Override credentials via ENV if you don't want the defaults.
seed_email = ENV.fetch("SEED_USER_EMAIL", "you@example.com")
seed_password = ENV.fetch("SEED_USER_PASSWORD", "password")

user = User.find_or_create_by!(email_address: seed_email) do |u|
  u.password = seed_password
end

family = user.families.first
if family.nil?
  family = Family.create!(name: "Our Family", owner: user, bank_holiday_division: "england-and-wales")
  Membership.create!(user: user, family: family)
  puts "Created family \"#{family.name}\" with login #{seed_email} / #{seed_password}"
end

# Seed UK Bank Holidays
puts "Seeding UK Bank Holidays..."
UkBankHolidaysService.sync!
puts "Bank holidays count: #{BankHoliday.count}"

# Seed default people if none exist
if family.people.none?
  puts "Creating initial people..."
  family.people.create!(
    name: "Chris",
    color: "#2563eb", # Blue
    allowance_unit: "days",
    allowance_amount: 25.0,
    hours_per_day: 7.5,
    include_bank_holidays: false,
    leave_year_start_month: 1,
    leave_year_start_day: 1
  )

  family.people.create!(
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
if family.school_holidays.none?
  puts "Creating sample UK school holidays..."
  current_year = Date.current.year
  [ current_year, current_year + 1 ].each do |year|
    family.school_holidays.create!(
      title: "February Half Term #{year}",
      start_date: Date.new(year, 2, 16),
      end_date: Date.new(year, 2, 20),
      color: "#f59e0b"
    )

    family.school_holidays.create!(
      title: "Easter Holidays #{year}",
      start_date: Date.new(year, 3, 30),
      end_date: Date.new(year, 4, 10),
      color: "#f59e0b"
    )

    family.school_holidays.create!(
      title: "May Half Term #{year}",
      start_date: Date.new(year, 5, 25),
      end_date: Date.new(year, 5, 29),
      color: "#f59e0b"
    )

    family.school_holidays.create!(
      title: "Summer Holidays #{year}",
      start_date: Date.new(year, 7, 23),
      end_date: Date.new(year, 9, 2),
      color: "#f59e0b"
    )

    family.school_holidays.create!(
      title: "October Half Term #{year}",
      start_date: Date.new(year, 10, 26),
      end_date: Date.new(year, 10, 30),
      color: "#f59e0b"
    )

    family.school_holidays.create!(
      title: "Christmas Holidays #{year}",
      start_date: Date.new(year, 12, 21),
      end_date: Date.new(year + 1, 1, 1),
      color: "#f59e0b"
    )
  end
end
