Rails.application.routes.draw do
  post "/paymentIntents/create" => "rebill#create"
end
