$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib/"
require 'repositories_helper_patch'
require 'repository_patch'
require 'view_repositories_hook'
require 'repositories_controller_patch'
Redmine::Plugin.register :redmine_github_integration do
  name 'Redmine Github Integration plugin'
  author 'Target Integration'
  description 'This plugin allows you to Integrate github into Redmine'
  version '0.0.1'
  url 'http://targetintegration.com'
  author_url 'http://targetintegration.com'

  settings default: {}, partial: 'settings/git_settings.html.erb'
  Repository.safe_attributes 'git_clone_url'

  Redmine::AccessControl.map do |map|
    map.project_module :repository do |map|
      map.permission :pull_repository, {:repositories => [:fetch_repo]}, :require => :loggedin
    end
  end

end
