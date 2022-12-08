# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionSections::ConsultationComponent, type: :component do
  let(:component) { described_class.new(planning_application: nil) }

  it "renders 'not applicable' message" do
    render_inline(component)

    expect(page).to have_content(
      "Consultation is not applicable for proposed permitted development."
    )
  end
end
