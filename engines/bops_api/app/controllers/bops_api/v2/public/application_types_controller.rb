# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class ApplicationTypesController < PublicController
        def index
          @application_types = current_local_authority.application_types.select(:name, :code, :suffix).order(:code)

          respond_to do |format|
            format.json
          end
        end
      end
    end
  end
end
