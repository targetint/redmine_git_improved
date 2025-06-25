class AddColumnGitCloneUrlRepository < ActiveRecord::Migration[6.1]
  def change
    unless column_exists?(:repositories, :git_clone_url)
      add_column :repositories, :git_clone_url, :string, default: ''
    end
  end
end
