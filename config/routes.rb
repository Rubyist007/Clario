require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  post "/paymentIntents/create" => "rebill#create"
end
