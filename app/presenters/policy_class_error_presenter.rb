# frozen_string_literal: true

class PolicyClassErrorPresenter < ErrorPresenter
  private

  def attributes_map
    {"policies.comments.text": :existing_comment}
  end
end
