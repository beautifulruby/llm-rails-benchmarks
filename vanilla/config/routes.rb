Rails.application.routes.draw do
  resources :posts do
    resources :comments, only: [:create, :destroy]
  end

  root "posts#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
