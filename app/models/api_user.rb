class ApiUser < ApplicationRecord
  validates_presence_of :name, :token
end
