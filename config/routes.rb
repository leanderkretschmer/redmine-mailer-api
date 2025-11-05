# Routes für das User Mails API Plugin
# Diese Routes werden zu den bestehenden Routes hinzugefügt

# Route für E-Mail-Suche muss vor den user_id-basierten Routes stehen
match 'users/mails(.:format)', :to => 'user_mails#search', :via => [:get], :as => 'search_user_mail'

match 'users/:user_id/mails(.:format)', :to => 'user_mails#index', :via => [:get], :as => 'user_mails'
match 'users/:user_id/mails(.:format)', :to => 'user_mails#create', :via => [:post]
match 'users/:user_id/mails/:id(.:format)', :to => 'user_mails#show', :via => [:get], :as => 'user_mail'
match 'users/:user_id/mails/:id(.:format)', :to => 'user_mails#update', :via => [:put, :patch]
match 'users/:user_id/mails/:id(.:format)', :to => 'user_mails#destroy', :via => [:delete]

