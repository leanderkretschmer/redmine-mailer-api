# Redmine User Mails API Plugin
# Plugin für Redmine 6, das die API um E-Mail-Verwaltung erweitert

require 'redmine'

Redmine::Plugin.register :redmine_mailer_api do
  name 'Redmine User Mails API'
  author 'Leander Kretschmer'
  description 'Erweitert die Redmine API um die Möglichkeit, mehrere E-Mails pro User zu verwalten'
  version '0.0.1'
  url 'https://github.com/leanderkretschmer/redmine-mailer-api'
  author_url 'https://github.com/leanderkretschmer'

  requires_redmine version_or_higher: '6.0.0'
end

# Routes hinzufügen - Routes werden direkt registriert
Rails.application.config.to_prepare do
  Rails.application.routes.draw do
    # Route für E-Mail-Suche - verwende einen eindeutigen Pfad ohne user_id
    # Dieser Pfad kollidiert nicht mit users/:user_id/mails
    match 'mail_search(.:format)', :to => 'user_mails#search', :via => [:get], :as => 'search_user_mail'
    
    match 'users/:user_id/mails(.:format)', :to => 'user_mails#index', :via => [:get], :as => 'user_mails'
    match 'users/:user_id/mails(.:format)', :to => 'user_mails#create', :via => [:post]
    match 'users/:user_id/mails/:id(.:format)', :to => 'user_mails#show', :via => [:get], :as => 'user_mail'
    match 'users/:user_id/mails/:id(.:format)', :to => 'user_mails#update', :via => [:put, :patch]
    match 'users/:user_id/mails/:id(.:format)', :to => 'user_mails#destroy', :via => [:delete]
  end
end

