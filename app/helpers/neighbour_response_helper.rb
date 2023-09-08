# frozen_string_literal: true

module NeighbourResponseHelper
  def response_been_truncated?(response)
    response.truncated_comment.length != response.comment.length
  end

  def truncated_length(response)
    response.truncated_comment.length - 3
  end
end
