class BankHolidaysController < ApplicationController
  def index
    @division = params[:division].presence || "england-and-wales"
    @year = (params[:year].presence || Date.current.year).to_i
    @bank_holidays = BankHoliday.for_division(@division)
                                .where("strftime('%Y', date) = ?", @year.to_s)
                                .order(:date)
  end

  def sync
    count = UkBankHolidaysService.sync!
    redirect_to bank_holidays_path, notice: "Successfully updated UK Bank Holidays (#{count} entries)."
  end
end
