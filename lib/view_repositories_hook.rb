class ViewRepositoriesHook < Redmine::Hook::ViewListener
	render_on :view_repositories_show_contextual,
                partial: 'hooks/view_repositories_hook'
end