# frozen_string_literal: true

class DocumentsController < AuthenticationController

  def document_params
    params.require(:document).permit(:name, :plan, :planning_application_id)
  end

end
