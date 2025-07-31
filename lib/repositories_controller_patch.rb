module RepositoriesControllerPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
        # validate :fetch_repository, :if => Proc.new { |repo| repo.new_record? && repo.is_a?(Repository::Git)}
        # , :if => Proc.new { |repo| repo.new_record? && repo.repository_scm == 'Git'}
        alias_method :find_project_repository_without_patch, :find_project_repository
        alias_method :find_project_repository, :find_project_repository_with_patch
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
        rev = params[:rev]
        Dir.chdir(directory) do
          # Pull changes from the remote repository
          # system("git pull #{remote_url}")
          system("cd  #{directory}; git checkout #{rev}; git reset --hard;")
          repo = Rugged::Repository.new(directory)
          remote = repo.remotes["origin"]
          remote.fetch(
            credentials: Rugged::Credentials::UserPassword.new(
              username: @repository.login,
              password: @repository.password
            )
          )
          remote_rev = "origin/#{rev}"
          remote_branch = repo.references["refs/remotes/#{remote_rev}"]
          # Fast-forward local branch (e.g., main)
          local_branch = repo.branches[remote_rev]

          # Set local branch HEAD to remote if it's a fast-forward
          if repo.descendant_of?(remote_branch.target_id, local_branch.target_id)
            # Update working directory
            repo.checkout_tree(remote_branch.target.tree, strategy: :force)
            repo.references.update("refs/heads/#{remote_rev}", remote_branch.target_id)
            # puts "Fast-forwarded to latest origin/#{remote_rev}."
          else
            # puts "Cannot fast-forward: local branch has diverged."
          end
          # Rails.logger.info "**************#{repo.head.name}***************"
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
      redirect_to "/projects/#{@project.identifier}/repository/#{@repository.id}?rev=#{rev}"
    end

    def find_project_repository_with_patch
      @project = Project.find(params[:id])
      if params[:repository_id].present?
        @repository = @project.repositories.find_by_identifier_param(params[:repository_id])
      else
        @repository = @project.repository || @project.repositories.first
      end
      (render_404; return false) unless @repository
      @path = params[:path].is_a?(Array) ? params[:path].join('/') : params[:path].to_s

      if @repository.git_clone_url.present? &&
        @repository.login.present? &&
        @repository.password.present? &&
        Setting.plugin_redmine_git_improved['destination_path'].present?
        repo = Rugged::Repository.new(@repository.url)
        repo_path = @repository.url.sub(/\.git\/?$/, "")
        local_branch_names = repo.branches.each(:local).map(&:name)
        repo.branches.each(:remote) do |remote_branch|
          local_equivalent = remote_branch.name.sub('origin/', '')
          next if local_equivalent.downcase == 'head'
          unless local_branch_names.include?(local_equivalent)
            system("cd  #{repo.path.sub(/\.git\/?$/, "")}; git checkout -B #{local_equivalent} #{remote_branch.name}")
          end
        end
     end
      @rev = params[:rev].to_s.strip.presence || @repository.default_branch
      @rev_to = params[:rev_to].to_s.strip.presence
      # raise InvalidRevisionParam unless valid_name?(@rev_to)
    rescue ActiveRecord::RecordNotFound
      render_404
    rescue InvalidRevisionParam
      show_error_not_found
    end
  end
end
unless RepositoriesController.included_modules.include?(RepositoriesControllerPatch)
    RepositoriesController.send(:include, RepositoriesControllerPatch)
end