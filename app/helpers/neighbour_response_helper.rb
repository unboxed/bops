# frozen_string_literal: true

module NeighbourResponseHelper
  def response_been_truncated?(response, text)
    response.truncated_comment.length != text.length
  end

  def truncated_length(response)
    response.truncated_comment.length - 3
  end
end
