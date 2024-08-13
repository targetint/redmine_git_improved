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
      if git_clone_url.present? && login.present? && password.present? && Setting.plugin_redmine_github_integration['destination_path'].present?
        begin
          dest = Setting.plugin_redmine_github_integration['destination_path']
          credentials = Rugged::Credentials::UserPassword.new(
                          username: login,
                          password: password
                        )
          folder = git_clone_url.split('/').last.split('.').first
          if Dir.exist?(dest+"/"+folder)
            folder = folder + rand(50).to_s
          end
          Dir.mkdir dest+"/"+folder
          a = Rugged::Repository.clone_at(git_clone_url, dest+"/"+folder, {
           credentials: credentials
          })
          self.url = a.path
        rescue
          errors.add :base, "Cannot fetch the repo, Please check the credentials or contact administrator"
        end
      end
    end
  end
end
unless Repository.included_modules.include?(RepositoryPatch)
    Repository.send(:include, RepositoryPatch)
end