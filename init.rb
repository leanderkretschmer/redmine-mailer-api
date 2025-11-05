require 'redmine'

Redmine::Plugin.register :redmine_mailer_api do
  name 'Redmine User Mails API'
  author 'Leander Kretschmer'
  description 'Erweitert die Redmine API um die Möglichkeit, mehrere E-Mails pro User zu verwalten'
  version '0.0.4'
  url 'https://github.com/leanderkretschmer/redmine-mailer-api'
  author_url 'https://github.com/leanderkretschmer'
  requires_redmine version_or_higher: '6.0.0'
end
