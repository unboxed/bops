# frozen_string_literal: true

class MigrateSiteVisitDocumentsToOwnerAssociation < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL
      UPDATE documents
      SET owner_id = site_visit_id, owner_type = 'SiteVisit', site_visit_id = NULL
      WHERE site_visit_id IS NOT NULL
    SQL
  end

  def down
    execute <<~SQL
      UPDATE documents
      SET site_visit_id = owner_id, owner_id = NULL, owner_type = NULL
      WHERE owner_type = 'SiteVisit'
    SQL
  end
end
