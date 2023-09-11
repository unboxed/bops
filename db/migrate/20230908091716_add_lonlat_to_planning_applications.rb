# frozen_string_literal: true

class AddLonlatToPlanningApplications < ActiveRecord::Migration[7.0]
  def up
    change_table :planning_applications do |t|
      t.st_point :lonlat, geographic: true
      t.index :lonlat, using: :gist
    end

    PlanningApplication.find_each do |record|
      next if record.latitude.nil? || record.longitude.nil?

      record.update!(
        lonlat: "POINT(#{record.longitude.to_f} #{record.latitude.to_f})"
      )
    end
  end

  def down
    PlanningApplication.find_each do |record|
      next if record.lonlat.nil?

      latitude = record.lonlat.y
      longitude = record.lonlat.x
      record.update!(
        latitude: latitude.to_s,
        longitude: longitude.to_s
      )
    end

    remove_column :planning_applications, :lonlat
  end
end
