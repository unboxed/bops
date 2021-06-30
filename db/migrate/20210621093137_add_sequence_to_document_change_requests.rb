class AddSequenceToDocumentChangeRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :document_change_requests, :sequence, :integer
  end
end
