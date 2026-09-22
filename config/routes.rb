Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  root "calendar#show"

  resource :calendar, only: [ :show ], controller: "calendar"
  resource :calendar_layout, only: [ :update ]
  resource :account, only: [ :edit, :update ] do
    resources :invitations, only: [ :new, :create, :destroy ]
    resources :memberships, only: [ :destroy ]
  end
  resource :profile, only: [ :edit, :update ]

  get "invitations/:token/accept", to: "invitation_acceptances#show", as: :accept_invitation
  post "invitations/:token/accept", to: "invitation_acceptances#create", as: :accept_invitation_create

  resources :people do
    resources :leave_ranges, only: [ :index, :new, :create ]
  end

  resources :leave_ranges, only: [ :index, :edit, :update, :destroy ]
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
