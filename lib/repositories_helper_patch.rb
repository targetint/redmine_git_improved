module RepositoriesHelperPatch
    def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
            unloadable
            alias_method :git_field_tags_without_patch, :git_field_tags
            alias_method :git_field_tags, :git_field_tags_with_patch
        end
    end
    module InstanceMethods

        def git_field_tags_with_patch(form, repository)
          content_tag(
              'p',
              form.text_field(
                :git_clone_url, :label => "Git Clone URL",
                :size => 60, :required => true,
                :disabled => !repository.safe_attribute?('url')
              ) + "<em class='info'>Clone URL (https://github.com/git/git_repo.git)</em>".html_safe) +
            content_tag(
              'p',
              form.text_field(
                :login, :label => "Login",
                :size => 60, :required => true,
                :disabled => !repository.safe_attribute?('url')
              )) +
            content_tag(
              'p',
              form.text_field(
                :password, :label => "Git personal access token",
                :size => 60, :required => true,
                :disabled => !repository.safe_attribute?('url')
              )) +
            content_tag(
              'p',
              form.text_field(
                :url, :label => l(:field_path_to_repository),
                :size => 60, :required => true,
                :disabled => true
              ) + scm_path_info_tag(repository)) +
            scm_path_encoding_tag(form, repository) +
            content_tag(
              'p',
              form.check_box(
                :report_last_commit,
                :label => l(:label_git_report_last_commit)
              )
            )
        end
    end
end
unless RepositoriesHelper.included_modules.include?(RepositoriesHelperPatch)
    RepositoriesHelper.send(:include, RepositoriesHelperPatch)
end