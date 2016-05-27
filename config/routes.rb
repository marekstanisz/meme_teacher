# encoding: UTF-8

MemeCaptainWeb::Application.routes.draw do
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)
  concern :paginatable do
    get '(page/:page)', action: :index, on: :collection, as: ''
  end

  concern :show_paginatable do
    get '(page/:page)', action: :show, on: :collection, as: ''
  end

  get 'home/index'

  resources :gend_images, concerns: :paginatable

  resources :gend_image_pages, only: :show

  resources :pending_gend_images, only: :show

  resources :gend_thumbs, only: :show

  resource :session, only: [:create, :destroy, :new]

  resources :src_images, concerns: :paginatable

  resources :pending_src_images, only: :show

  resources :src_sets, except: :new, concerns: :paginatable

  resources :src_thumbs, only: :show

  resources :users, only: [:create, :new]

  resource :my, only: :show, controller: :my, concerns: :show_paginatable

  resources :terms, only: :index

  resource :search,
           only: :show,
           controller: :search,
           concerns: :show_paginatable

  resources :stats, only: :create

  resources :errors, only: :index

  resource :api_token, only: :create

  resource :dashboard, only: :show, controller: :dashboard

  resources :gend_image_scripts, only: :show

  root to: 'home#index'
end
