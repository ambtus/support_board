SupportBoard::Application.routes.draw do
  resources :users do
    resources :pseuds
  end

  resources :user_sessions
  match 'login' => 'user_sessions#new'
  match 'logout' => 'user_sessions#destroy' 

  root :to => "home#index"
end
