namespace :bank_holidays do
  desc "Sync UK Bank Holidays from gov.uk"
  task sync: :environment do
    puts "Syncing UK Bank Holidays..."
    count = UkBankHolidaysService.sync!
    puts "Synced #{count} bank holiday records."
  end
end
