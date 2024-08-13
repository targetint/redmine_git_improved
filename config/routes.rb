# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get '/repository/:id/fetch', as: 'fetch_repo', to: 'repositories#fetch_repo'
