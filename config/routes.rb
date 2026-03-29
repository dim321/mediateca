Rails.application.routes.draw do
  devise_for :users

  # === User-facing routes ===
  resources :media_files, only: [ :index, :show, :create, :destroy ]

  resources :playlists do
    resources :items, controller: "playlist_items", only: [ :create, :update, :destroy ]
    patch :reorder, on: :member
  end

  resources :devices, only: [ :index ] do
    get :schedule, on: :member
  end

  resources :auctions, only: [ :index, :show ] do
    resources :bids, only: [ :create ]
  end

  resources :broadcasts, only: [ :index, :create ]

  resource :balance, only: [ :show ]
  resources :top_ups, only: [ :create ] do
    collection do
      get :success
      get :cancel
    end
  end
  namespace :webhooks do
    post :stripe, to: "stripe#create"
  end

  # === Admin namespace ===
  namespace :admin do
    resources :users, only: [ :index, :update ]
    resources :devices do
      resources :time_slots, only: [ :index ] do
        post :generate, on: :collection
      end
    end

    resources :time_slots, only: [ :update ] do
      post :create_auction, on: :member
    end

    resources :device_groups do
      post :add_devices, on: :member
      delete "remove_device/:device_id", action: :remove_device, on: :member, as: :remove_device
    end
  end

  # === Device API ===
  namespace :api do
    namespace :v1 do
      namespace :device do
        get :schedule, to: "schedules#show"
        post :heartbeat, to: "heartbeats#create"
        post :broadcast_status, to: "broadcast_statuses#create"
      end
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "media_files#index"
end
