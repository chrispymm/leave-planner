# Seed a default User + Account so there is somewhere to log in.
# Override credentials via ENV if you don't want the defaults.
seed_email = ENV.fetch("SEED_USER_EMAIL", "you@example.com")
seed_password = ENV.fetch("SEED_USER_PASSWORD", "password")

user = User.find_or_create_by!(email_address: seed_email) do |u|
  u.password = seed_password
end

account = user.accounts.first
if account.nil?
  account = Account.create!(name: "Our Account", owner: user, bank_holiday_division: "england-and-wales")
  Membership.create!(user: user, account: account)
  puts "Created account \"#{account.name}\" with login #{seed_email} / #{seed_password}"
end

# Seed UK Bank Holidays
puts "Seeding UK Bank Holidays..."
UkBankHolidaysService.sync!
puts "Bank holidays count: #{BankHoliday.count}"

# Seed default people if none exist
if account.people.none?
  puts "Creating initial people..."
  account.people.create!(
    name: "Chris",
    color: "#2563eb", # Blue
    allowance_unit: "days",
    allowance_amount: 25.0,
    hours_per_day: 7.5,
    include_bank_holidays: false,
    leave_year_start_month: 1,
    leave_year_start_day: 1
  )

  account.people.create!(
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

# Seed a sample School Holidays calendar if the account has no calendars yet
if account.additional_calendars.none?
  puts "Creating sample School Holidays calendar..."
  calendar = account.additional_calendars.create!(
    name: "School Holidays",
    description: "School terms and holiday dates",
    color: "#f59e0b"
  )

  current_year = Date.current.year
  [ current_year, current_year + 1 ].each do |year|
    [
      [ "February Half Term #{year}", Date.new(year, 2, 16), Date.new(year, 2, 20) ],
      [ "Easter Holidays #{year}", Date.new(year, 3, 30), Date.new(year, 4, 10) ],
      [ "May Half Term #{year}", Date.new(year, 5, 25), Date.new(year, 5, 29) ],
      [ "Summer Holidays #{year}", Date.new(year, 7, 23), Date.new(year, 9, 2) ],
      [ "October Half Term #{year}", Date.new(year, 10, 26), Date.new(year, 10, 30) ],
      [ "Christmas Holidays #{year}", Date.new(year, 12, 21), Date.new(year + 1, 1, 1) ]
    ].each do |title, start_date, end_date|
      calendar.additional_calendar_entries.create!(
        title: title,
        start_date: start_date,
        end_date: end_date
      )
    end
  end
end
