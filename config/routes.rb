SupportBoard::Application.routes.draw do
  resources :users do
    resources :support_tickets
    resources :code_tickets
  end

  resources :user_sessions
  match 'login' => 'user_sessions#new'
  match 'logout' => 'user_sessions#destroy'

  resources :faqs
  resources :release_notes
  resources :support_tickets
  resources :code_tickets

  match 'github' => 'github#push', :via => "post"

  match 'support' => 'home#support'
  root :to => "home#index"
end
