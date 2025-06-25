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
      if repo.branches['origin/master']
        system("cd  #{repo_path}; git checkout -B master origin/master")
      end
     end

      @rev = params[:rev].to_s.strip.presence || @repository.default_branch
      # raise InvalidRevisionParam unless valid_name?(@rev)
      if @rev == "(no branch)"
        if @repository.git_clone_url.present? &&
          @repository.login.present? &&
          @repository.password.present? &&
          Setting.plugin_redmine_git_improved['destination_path'].present?
          repo = Rugged::Repository.new(@repository.url)
          repo_path = @repository.url.sub(/\.git\/?$/, "")
          if repo.branches['main']
            # repo.checkout('main')
            system("cd  #{repo_path}; git checkout -B main main")
          elsif repo.branches['origin/main']
            # repo.checkout('origin/main')
            system("cd  #{repo_path}; git checkout -B main origin/main")
          elsif repo.branches['origin/master']
            # repo.checkout('origin/master')
            system("cd  #{repo_path}; git checkout -B master origin/master")
          elsif repo.branches['master']
            # repo.checkout('master')
            system("cd  #{repo_path}; git checkout -B master master")
          else
            # repo.checkout(repo.branches.first.name)
            system("cd  #{repo_path}; git checkout -B #{repo.branches.first.name} #{repo.branches.first.name}")
          end
          @rev = params[:rev].to_s.strip.presence || @repository.default_branch
         end
      end

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