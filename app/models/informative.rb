# frozen_string_literal: true

class Informative < ApplicationRecord
  belongs_to :informative_set

  validates :title, :text, presence: true

  validates :title, :text, uniqueness: {scope: :informative_set_id}
end
