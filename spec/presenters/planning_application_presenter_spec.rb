# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationPresenter do
  subject(:presenter) { described_class.new(instance_double("view_context"), planning_application) }

  let!(:planning_application) { create(:planning_application) }

  it "delegates missing methods to its application" do
    expect(presenter.id).to eq planning_application.id
  end

  it "advertises the methods it responds to" do
    expect(presenter).to respond_to :id
  end
end
