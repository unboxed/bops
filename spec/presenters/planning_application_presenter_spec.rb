# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:not_started_planning_application) }

  it "delegates missing methods to its application" do
    expect(presenter.id).to eq planning_application.id
  end

  it "advertises the methods it responds to" do
    expect(presenter).to respond_to :id
  end

  describe "#next_relevant_date_tag" do
    [
      [:not_started, "Expiry date: ", :expiry_date],
      [:determined, "Granted at: ", :determined_at],
      [:returned, "Returned at: ", :returned_at],
      [:withdrawn, "Withdrawn at: ", :withdrawn_at]
    ].each do |state, label, date|
      context "when the application is #{state.to_s.humanize}" do
        let(:planning_application) { create("#{state}_planning_application") }

        it "shows the '#{date}' date" do
          date = planning_application.send(date).to_formatted_s(:day_month_year)

          expect(presenter.next_relevant_date_tag).to include date
        end

        it "shows a '#{label}' label" do
          expect(presenter.next_relevant_date_tag).to include label
        end
      end
    end
  end
end
