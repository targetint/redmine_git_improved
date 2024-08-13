module RepositoriesControllerPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
        # validate :fetch_repository, :if => Proc.new { |repo| repo.new_record? && repo.is_a?(Repository::Git)}
        # , :if => Proc.new { |repo| repo.new_record? && repo.repository_scm == 'Git'}
        # alias_method :git_field_tags_without_patch, :git_field_tags
        # alias_method :git_field_tags, :git_field_tags_with_patch
        skip_before_action :find_project_repository, only: [:fetch_repo]
        skip_before_action :authorize, only: [:fetch_repo]
    end
  end
  module InstanceMethods
    def fetch_repo
      begin
        find_repository
        authorize
        repository_url = @repository.git_clone_url
        remote_url = "https://#{@repository.login}:#{@repository.password}@#{repository_url.sub('https://', '')}"
        directory = @repository.url.sub(".git/","")

        # Change to the repository directory
        Dir.chdir(directory) do
          # Pull changes from the remote repository
          system("git pull #{remote_url}")
        end

        # Step 2: Get the current branch and the corresponding remote branch
        # current_branch = repo.branches[repo.head.name.sub('refs/heads/', '')]
        # remote_branch = repo.branches["origin/#{current_branch.name}"]

        # # Step 3: Check if a fast-forward merge is possible
        # # Perform the fast-forward merge
        # current_branch.move(remote_branch.target_id)
        # remote.fetch
        # remote_branch_name = "refs/remotes/origin/#{repo.head.name.split('/').last}"
        # remote_branch = repo.references[remote_branch_name].target
        # # Step 3: Merge the remote branch into the current branch
        # merge_index = repo.merge_commits(repo.head.target, remote_branch)
        flash[:notice] = "Pulled the repo successfully"
      rescue => e
        flash[:error] = "Error in pull repository please contact administrator #{e.message}"
      end
      redirect_to "/projects/#{@project.identifier}/repository/#{@repository.id}"
    end
  end
end
unless RepositoriesController.included_modules.include?(RepositoriesControllerPatch)
    RepositoriesController.send(:include, RepositoriesControllerPatch)
end