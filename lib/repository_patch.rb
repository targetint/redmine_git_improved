module RepositoryPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
        validate :fetch_repository, :if => Proc.new { |repo| repo.new_record? && repo.is_a?(Repository::Git)}
        # , :if => Proc.new { |repo| repo.new_record? && repo.repository_scm == 'Git'}
        # alias_method :git_field_tags_without_patch, :git_field_tags
        # alias_method :git_field_tags, :git_field_tags_with_patch
    end
  end
  module InstanceMethods
    def fetch_repository
      if git_clone_url.present? && login.present? && password.present? && Setting.plugin_redmine_git_improved['destination_path'].present?
        begin
          dest = Setting.plugin_redmine_git_improved['destination_path']
          credentials = Rugged::Credentials::UserPassword.new(
                          username: login,
                          password: password
                        )
          folder = git_clone_url.split('/').last.split('.').first
          if Dir.exist?(dest+"/"+folder)
            folder = folder + rand(50).to_s
          end
          Dir.mkdir dest+"/"+folder
          # repo = Rugged::Repository.clone_at(git_clone_url, dest+"/"+folder, {
          #  credentials: credentials
          # })
          repo = Rugged::Repository.clone_at(git_clone_url, dest+"/"+folder, {
           credentials: credentials, bare: false
          })
          # repo = Rugged::Repository.new(repo.path)
          remote = repo.remotes['origin']
          # Fetch from origin
          remote.fetch(credentials: credentials)
          if repo.branches['main']
            # repo.checkout('main')
            # system("cd  #{url.sub(/\.git\/?$/, "")}; git checkout -B main")
          elsif repo.branches['origin/main']
            # repo.checkout('origin/main')
            # system("cd  #{url.sub(/\.git\/?$/, "")}; git checkout -B main origin/main")
          elsif repo.branches['origin/master']
            repo.checkout('origin/master')
            system("cd  #{url.sub(/\.git\/?$/, "")}; git checkout -B master origin/master")
          elsif repo.branches['master']
            repo.checkout('master')
            system("cd  #{url.sub(/\.git\/?$/, "")}; git checkout -B master master")
          end 
          self.url = repo.path
        rescue => e
          Rails.logger.error "git_fetch_repository error #{e}"
          errors.add :base, "Cannot fetch the repo, Please check the credentials or contact administrator"
        end
      end
    end
  end
end
unless Repository.included_modules.include?(RepositoryPatch)
    Repository.send(:include, RepositoryPatch)
end