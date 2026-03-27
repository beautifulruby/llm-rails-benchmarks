Rails.application.routes.draw do
  resources :posts do
    resources :comments, only: [:create, :update, :destroy] do
      member do
        patch :approve
        patch :reject
      end
    end
  end

  root "posts#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
