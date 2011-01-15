SupportBoard::Application.routes.draw do
  resources :users
  resources :user_sessions
  match 'login' => 'user_sessions#new'
  match 'logout' => 'user_sessions#destroy'

  resources :faqs
  resources :release_notes
  resources :support_tickets
  resources :code_tickets
  resources :code_commits

  match 'github' => 'github#push', :via => "post"

  match 'comments' => 'support_tickets#comments'
  match 'support' => 'home#support'
  root :to => "home#index"
end
