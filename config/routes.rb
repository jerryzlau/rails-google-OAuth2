Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'login', to: 'auth#fetch_code'
  get 'oauth2callback', to: 'auth#oauth2callback'
end
