# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::QueryService do
  let(:scope) { PlanningApplication.all }
  let(:params) { {} }
  let(:service) { described_class.new(scope, params) }

  describe "call" do
    context "when page and maxresults are provided" do
      before do
        create_list(:planning_application, 25)
      end

      let(:params) { {page: 2, maxresults: 5} }

      it "paginates the results correctly" do
        pagy, _ = service.call
        expect(pagy).to have_attributes(
          page: 2,
          limit: 5,
          count: 25,
          pages: 5,
          from: 6,
          to: 10
        )
      end

      context "when exceeding the maxresults limit" do
        let(:params) { {maxresults: 50} }

        it "limits the results to MAXRESULTS_LIMIT" do
          pagy, _ = service.call
          expect(pagy.limit).to eq(BopsApi::Pagination::MAXRESULTS_LIMIT)
        end
      end
    end

    context "when given ids" do
      let(:planning_applications) { create_list(:planning_application, 5) }
      let(:ids) { planning_applications[0, 2].map(&:id) }
      let(:params) { {ids: ids} }

      it "filters planning applications by provided IDs" do
        results = service.call.last
        expect(results.ids).to match_array(ids)
        expect(results.count).to eq(2)
      end
    end
  end
end
