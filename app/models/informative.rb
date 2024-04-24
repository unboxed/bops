# frozen_string_literal: true

class Informative < ApplicationRecord
  belongs_to :informative_set
  acts_as_list scope: :informative_set

  validates :title, :text, presence: true, uniqueness: {scope: :informative_set_id}
end
