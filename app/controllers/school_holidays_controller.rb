class SchoolHolidaysController < ApplicationController
  before_action :set_school_holiday, only: [ :edit, :update, :destroy ]

  def index
    @school_holidays = SchoolHoliday.order(:start_date)
  end

  def new
    @school_holiday = SchoolHoliday.new(
      start_date: Date.current,
      end_date: Date.current + 7.days,
      color: "#f59e0b"
    )
  end

  def edit
  end

  def create
    @school_holiday = SchoolHoliday.new(school_holiday_params)
    if @school_holiday.save
      redirect_to school_holidays_path, notice: "#{@school_holiday.title} was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @school_holiday.update(school_holiday_params)
      redirect_to school_holidays_path, notice: "#{@school_holiday.title} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @school_holiday.destroy
    redirect_to school_holidays_path, notice: "#{@school_holiday.title} was deleted."
  end

  private

  def set_school_holiday
    @school_holiday = SchoolHoliday.find(params[:id])
  end

  def school_holiday_params
    params.require(:school_holiday).permit(:title, :start_date, :end_date, :color, :notes)
  end
end
