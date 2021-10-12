# frozen_string_literal: true

module Api
  module V1
    module Errors
      class WrongFileTypeError < ArgumentError
        def initialize(msg, uri)
          @filename = Pathname.new(uri).basename

          super(msg)
        end

        def message
          "The document \"#{@filename}\" doesn't match our accepted file types"
        end
      end
    end
  end
end
