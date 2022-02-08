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

      class GetFileError < StandardError
        def initialize(msg, uri)
          @filename = Pathname.new(uri).basename
          @uri = uri

          super(msg)
        end

        def message
          "The document: '#{@filename}' at location: '#{@uri}' does not exist or is forbidden"
        end
      end
    end
  end
end
