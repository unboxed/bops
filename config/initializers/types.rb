# frozen_string_literal: true

require "types/array_type"
require "types/enum_type"
require "types/geojson_type"
require "types/list_type"

ActiveModel::Type.register :array, ArrayType
ActiveModel::Type.register :enum, EnumType
ActiveModel::Type.register :geojson, GeojsonType
ActiveModel::Type.register :list, ListType
