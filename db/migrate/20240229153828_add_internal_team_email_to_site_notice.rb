# frozen_string_literal: true

class AddInternalTeamEmailToSiteNotice < ActiveRecord::Migration[7.1]
  def change
    add_column :site_notices, :internal_team_email, :string
  end
end
