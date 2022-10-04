# frozen_string_literal: true

class ChangeSummaryOfWorksToAssessmentDetails < ActiveRecord::Migration[6.1]
  def up
    rename_table :summary_of_works, :assessment_details

    add_column :assessment_details, :category, :string unless column_exists?(:assessment_details, :category)

    AssessmentDetail.find_each do |assessment_detail|
      assessment_detail.update(category: "summary_of_work")
    end

    change_column_null :assessment_details, :category, false
  end

  def down
    remove_column :assessment_details, :category if column_exists?(:assessment_details, :category)

    rename_table :assessment_details, :summary_of_works
  end
end
