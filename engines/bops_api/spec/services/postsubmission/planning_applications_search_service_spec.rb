# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Postsubmission::PlanningApplicationsSearchService do
  let(:scope) { PlanningApplication.all }
  let(:params) { {} }
  let(:service) { described_class.new(scope, params) }
  let(:pagy_and_results) { service.call }
  let(:pagy) { pagy_and_results.first }
  let(:results) { pagy_and_results.last }

  describe "#call" do
    context "when page and resultsPerPage are provided" do
      before { create_list(:planning_application, 25) }
      let(:params) { {page: 2, resultsPerPage: 5} }

      it "returns a Pagy object and results slice" do
        expect(pagy).to be_a(Pagy)
        expect(results.size).to eq(5)
      end

      context "when exceeding the resultsPerPage limit" do
        let(:params) { {resultsPerPage: 50} }

        it "limits the results to MAXRESULTS_LIMIT" do
          expect(pagy.limit).to eq(
            BopsApi::Postsubmission::PostsubmissionPagination::MAXRESULTS_LIMIT
          )
        end
      end
    end

    context "when performing a search" do
      let!(:matching_reference) do
        create(:planning_application)
      end
      let!(:matching_description) do
        create(:planning_application,
          description: "This is a unique description")
      end
      let!(:matching_address) do
        create(:planning_application,
          address_1: "123 Unique Road",
          county: "Greater London",
          town: "Unique Town",
          postcode: "SE21 7DN")
      end

      context "when searching by reference" do
        let(:params) { {query: matching_reference.reference} }

        it "returns applications matching the reference" do
          expect(results).to include(matching_reference)
          expect(results).not_to include(matching_description, matching_address)
        end
      end

      context "when searching by description" do
        let(:params) { {query: "unique description"} }

        it "returns applications matching the description" do
          expect(results).to include(matching_description)
          expect(results).not_to include(matching_reference, matching_address)
        end
      end

      context "when searching by address" do
        context "with address lines" do
          let(:params) { {query: "123 unique Road Unique town"} }

          it "returns applications matching the address" do
            expect(results).to include(matching_address)
            expect(results).not_to include(matching_reference, matching_description)
          end
        end

        context "with postcode" do
          context "with exact postcode query" do
            let(:params) { {query: "SE21 7DN"} }

            it "returns applications matching the postcode" do
              expect(results).to include(matching_address)
              expect(results).not_to include(matching_reference, matching_description)
            end
          end

          context "with postcode query" do
            let(:params) { {query: "se217Dn"} }

            it "returns applications matching the postcode" do
              expect(results).to include(matching_address)
              expect(results).not_to include(matching_reference, matching_description)
            end
          end
        end
      end

      context "when no search term matches" do
        let(:params) { {query: "noresults"} }

        it "returns no results" do
          expect(results).to be_empty
        end
      end
    end

    context "when filtering by date ranges" do
      let!(:old) do
        create(:planning_application,
          :planning_permission, :consulting,
          received_at: 10.days.ago,
          validated_at: 8.days.ago,
          published_at: 6.days.ago)
      end
      let!(:mid) do
        create(:planning_application,
          :planning_permission, :consulting,
          received_at: 5.days.ago,
          validated_at: 4.days.ago,
          published_at: 3.days.ago)
      end
      let!(:newer) do
        create(:planning_application,
          :planning_permission, :consulting,
          received_at: 1.day.ago,
          validated_at: 1.day.ago,
          published_at: 1.day.ago)
      end

      before do
        old.consultation.update(end_date: 12.days.ago)
        mid.consultation.update(end_date: 5.days.ago)
        newer.consultation.update(end_date: 1.day.ago)
      end

      context "receivedAtFrom only" do
        let(:params) { {receivedAtFrom: 3.days.ago.to_date.iso8601} }

        it "returns applications received on or after the given date" do
          expect(results).to match_array([newer])
        end
      end

      context "receivedAtTo only" do
        let(:params) { {receivedAtTo: 6.days.ago.to_date.iso8601} }

        it "returns applications received on or before the given date" do
          expect(results).to match_array([old])
        end
      end

      context "receivedAtFrom and receivedAtTo" do
        let(:params) do
          {
            receivedAtFrom: 7.days.ago.to_date.iso8601,
            receivedAtTo: 2.days.ago.to_date.iso8601
          }
        end

        it "returns applications within the received date range" do
          expect(results).to match_array([mid])
        end
      end

      context "validatedAt range" do
        let(:params) do
          {
            validatedAtFrom: 5.days.ago.to_date.iso8601,
            validatedAtTo: 2.days.ago.to_date.iso8601
          }
        end

        it "returns applications within the validated date range" do
          expect(results).to match_array([mid])
        end
      end

      context "publishedAt range" do
        let(:params) do
          {
            publishedAtFrom: "2020-01-01",
            publishedAtTo: "2020-01-10"
          }
        end

        before do
          old.update!(published_at: "2020-01-01")
          mid.update!(published_at: "2020-01-05")
          newer.update!(published_at: "2020-02-01")
        end

        it "returns applications within the published date range" do
          expect(results).to match_array([old, mid])
        end
      end

      context "consultationEndDate range" do
        let(:params) do
          {
            consultationEndDateFrom: 6.days.ago.to_date.iso8601,
            consultationEndDateTo: 2.days.ago.to_date.iso8601
          }
        end

        it "returns applications with consultation end date in range" do
          expect(results).to match_array([mid])
        end
      end
    end

    context "when chaining multiple filters: date + search" do
      let!(:roof_a) do
        create(:planning_application,
          received_at: 5.days.ago,
          published_at: 5.days.ago,
          description: "A roof extension")
      end
      let!(:roof_b) do
        create(:planning_application,
          received_at: 3.days.ago,
          published_at: 3.days.ago,
          description: "A roof extension")
      end
      let!(:loft) do
        create(:planning_application,
          received_at: 3.days.ago,
          published_at: 3.days.ago,
          description: "A loft extension")
      end

      let(:params) do
        {
          receivedAtFrom: 4.days.ago.to_date.iso8601,
          publishedAtTo: 2.days.ago.to_date.iso8601,
          q: "roof"
        }
      end

      it "returns only applications matching both date filters and search" do
        expect(results).to match_array([roof_b])
      end
    end

    context "when chaining date + sortBy" do
      let!(:old_app) { create(:planning_application, published_at: 5.days.ago) }
      let!(:mid_app) { create(:planning_application, published_at: 3.days.ago) }
      let!(:new_app) { create(:planning_application, published_at: 1.day.ago) }

      let(:params) do
        {
          publishedAtFrom: 3.days.ago.to_date.iso8601,
          sortBy: "publishedAt",
          orderBy: "asc"
        }
      end

      it "returns filtered and sorted results" do
        expect(results).to eq([mid_app, new_app])
      end
    end
  end
end
