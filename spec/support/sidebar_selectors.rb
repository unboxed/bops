# frozen_string_literal: true

# Custom Capybara selectors for sidebar navigation in workflow specs
# These provide cleaner, more semantic ways to interact with the sidebar

Capybara.add_selector(:sidebar) do
  css { "nav.bops-sidebar" }
end

Capybara.add_selector(:active_sidebar_task) do
  xpath { |name| ".//li[contains(@class, 'bops-sidebar__task--active')][.//a[normalize-space()='#{name}']]" }
end

Capybara.add_selector(:completed_sidebar_task) do
  xpath { |name| ".//li[contains(@class, 'bops-sidebar__task')][.//svg[@aria-label='Completed']][.//a[normalize-space()='#{name}']]" }
end

Capybara.add_selector(:in_progress_sidebar_task) do
  xpath { |name| ".//li[contains(@class, 'bops-sidebar__task')][.//svg[@aria-label='In progress']][.//a[normalize-space()='#{name}']]" }
end

Capybara.add_selector(:not_started_sidebar_task) do
  xpath { |name| ".//li[contains(@class, 'bops-sidebar__task')][.//svg[@aria-label='Not started']][.//a[normalize-space()='#{name}']]" }
end

Capybara.add_selector(:action_required_sidebar_task) do
  xpath { |name| ".//li[contains(@class, 'bops-sidebar__task')][.//svg[@aria-label='Action required']][.//a[normalize-space()='#{name}']]" }
end
