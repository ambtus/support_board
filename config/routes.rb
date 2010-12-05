SupportBoard::Application.routes.draw do
  resources :users do
    resources :pseuds
    resources :support_tickets
    resources :code_tickets
  end

  resources :pseuds do
    resources :support_tickets
    resources :code_tickets
  end

  resources :user_sessions
  match 'login' => 'user_sessions#new'
  match 'logout' => 'user_sessions#destroy'

  resources :admin_sessions
  match 'admin/login' => 'admin_sessions#new'
  match 'admin/logout' => 'admin_sessions#destroy'

  resources :archive_faqs
  resources :known_issues
  resources :admin_posts
  resources :support_tickets
  resources :code_tickets

  match 'support' => 'home#support'
  root :to => "home#index"
end
