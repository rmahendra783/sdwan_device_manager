# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :devices, only: [:index, :show] do
        member do
          post :sync
        end
      end
    end
  end
end