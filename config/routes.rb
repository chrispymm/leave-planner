Rails.application.routes.draw do
  root "calendar#show"

  resource :calendar, only: [ :show ], controller: "calendar"

  resources :people
  resources :school_holidays
  resources :bank_holidays, only: [ :index ] do
    collection do
      post :sync
    end
  end

  resources :leave_entries, only: [ :create, :update, :destroy ] do
    collection do
      post :toggle
      post :bulk_create
      get :modal
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
