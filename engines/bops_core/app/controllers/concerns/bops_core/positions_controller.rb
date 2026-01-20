# frozen_string_literal: true

module BopsCore
  module PositionsController
    extend ActiveSupport::Concern

    included do
      wrap_parameters false

      before_action :set_collection
      before_action :set_record
    end

    def update
      respond_to do |format|
        format.json do
          if @record.insert_at(position)
            head :no_content
          else
            render json: @record.errors, status: :unprocessable_content
          end
        end
      end
    end

    private

    def set_collection
      raise NotImplementedError, "#{self.class.name} needs to implement #set_collection"
    end

    def set_record
      raise NotImplementedError, "#{self.class.name} needs to implement #set_record"
    end

    def position
      Integer(params.require(:position))
    end
  end
end
