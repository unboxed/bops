# frozen_string_literal: true

class BackfillDocumentOwnerFromNeighbourResponseId < ActiveRecord::Migration[7.2]
  def change
    up_only do
      safety_assured do
        execute <<~SQL
          UPDATE documents
            SET owner_type = 'NeighbourResponse',
                owner_id   = neighbour_response_id
          WHERE neighbour_response_id IS NOT NULL
            AND owner_id IS NULL
            AND owner_type IS NULL;
        SQL
      end
    end
  end
end
