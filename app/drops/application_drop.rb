# frozen_string_literal: true

class ApplicationDrop < Liquid::Drop
  class Routing
    include Rails.application.routes.url_helpers
    include Rails.application.routes.mounted_helpers
  end

  def initialize(model)
    @model = model
  end

  private

  def routes
    @routes ||= Routing.new
  end
end
