class PeopleController < ApplicationController
  before_action :set_person, only: [ :show, :edit, :update, :destroy ]

  def index
    @people = Person.order(:name)
  end

  def show
    redirect_to edit_person_path(@person)
  end

  def new
    @person = Person.new(
      allowance_unit: "days",
      allowance_amount: 25.0,
      hours_per_day: 7.5,
      include_bank_holidays: false,
      leave_year_start_month: 1,
      leave_year_start_day: 1,
      color: sample_color
    )
  end

  def edit
  end

  def create
    @person = Person.new(person_params)
    if @person.save
      redirect_to people_path, notice: "#{@person.name} was successfully added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @person.update(person_params)
      redirect_to people_path, notice: "#{@person.name} was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @person.destroy
    redirect_to people_path, notice: "#{@person.name} was deleted."
  end

  private

  def set_person
    @person = Person.find(params[:id])
  end

  def person_params
    params.require(:person).permit(
      :name,
      :color,
      :allowance_unit,
      :allowance_amount,
      :initial_remaining_allowance,
      :initial_allowance_date,
      :hours_per_day,
      :include_bank_holidays,
      :leave_year_start_month,
      :leave_year_start_day
    )
  end

  def sample_color
    colors = %w[#2563eb #db2777 #059669 #7c3aed #ea580c #0891b2 #d97706 #4f46e5]
    used = Person.pluck(:color)
    (colors - used).first || colors.sample
  end
end
