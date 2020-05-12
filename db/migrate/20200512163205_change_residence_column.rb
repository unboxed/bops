class ChangeResidenceColumn < ActiveRecord::Migration[6.0]
  def change
    change_column(:applicants, :residence_status,:boolean, null: false, default: false, )
  end
end
