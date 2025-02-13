# frozen_string_literal: true

require "types/enum_type"
require "types/list_type"

ActiveModel::Type.register :enum, EnumType
ActiveModel::Type.register :list, ListType
