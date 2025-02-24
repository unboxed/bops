# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  class ApplicationType < ApplicationRecord
    belongs_to :local_authority
    belongs_to :application_type
  end
end
