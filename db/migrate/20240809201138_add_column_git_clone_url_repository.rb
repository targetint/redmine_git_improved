class AddColumnGitCloneUrlRepository < ActiveRecord::Migration[6.1]
  def change
    add_column :repositories, :git_clone_url, :string, default: ''
  end
end
