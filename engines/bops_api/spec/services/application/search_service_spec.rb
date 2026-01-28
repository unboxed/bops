# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::SearchService do
  let(:scope) { PlanningApplication.all }
  let(:params) { {} }
  let(:service) { described_class.new(scope, params) }
  let(:pagy_and_results) { service.call }
  let(:pagy) { pagy_and_results.first }
  let(:results) { pagy_and_results.last }

  describe "call" do
    context "when page and maxresults are provided" do
      before do
        create_list(:planning_application, 25)
      end

      let(:params) { {page: 2, maxresults: 5} }

      it "paginates the results correctly" do
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
          expect(pagy.limit).to eq(BopsApi::Pagination::MAXRESULTS_LIMIT)
        end
      end
    end

    context "when performing a search" do
      let!(:matching_reference) { create(:planning_application) }
      let!(:matching_description) { create(:planning_application, description: "This is a unique description") }
      let!(:matching_address) { create(:planning_application, address_1: "123 Unique Road", county: "Greater London", town: "Unique Town", postcode: "SE21 7DN") }

      context "when searching by reference" do
        let(:params) { {q: matching_reference.reference} }

        it "returns applications matching the reference" do
          expect(results).to include(matching_reference)
          expect(results).not_to include(matching_description, matching_address)
        end
      end

      context "when searching by description" do
        let(:params) { {q: "unique description"} }

        it "returns applications matching the description" do
          expect(results).to include(matching_description)
          expect(results).not_to include(matching_reference, matching_address)
        end
      end

      context "when searching by address" do
        context "with address lines" do
          let(:params) { {q: "123 unique Road Unique town"} }

          it "returns applications matching the address" do
            expect(results).to include(matching_address)
            expect(results).not_to include(matching_reference, matching_description)
          end
        end

        context "with postcode" do
          context "with exact postcode query" do
            let(:params) { {q: "SE21 7DN"} }

            it "returns applications matching the postcode" do
              expect(results).to include(matching_address)
              expect(results).not_to include(matching_reference, matching_description)
            end
          end

          context "with postcode query" do
            let(:params) { {q: "se217Dn"} }

            it "returns applications matching the postcode" do
              expect(results).to include(matching_address)
              expect(results).not_to include(matching_reference, matching_description)
            end
          end
        end
      end

      context "when no search term matches" do
        let(:params) { {q: "noresults"} }

        it "returns no results" do
          expect(results).to be_empty
        end
      end
    end

    context "when filtering by application type codes" do
      let(:local_authority) { create(:local_authority) }
      let!(:ldc) { create(:application_type, code: "ldc.existing", local_authority:) }
      let!(:householder) { create(:application_type, :householder, local_authority:) }

      let!(:app1) { create(:planning_application, application_type: ldc) }
      let!(:app2) { create(:planning_application, application_type: householder) }
      let!(:app3) { create(:planning_application, application_type: householder, address_1: "Random street") }

      before do
        create(:application_type_config, :ldc_existing)
        create(:application_type_config, :ldc_proposed)
      end

      context "when no application type codes are provided" do
        let(:params) { {applicationType: [""]} }

        it "returns no applications" do
          expect(results).to match_array([])
        end
      end

      context "when one matching application type code is provided" do
        let(:params) { {applicationType: ["ldc.existing", "notvalid"]} }

        it "returns matching applications" do
          expect(results).to match_array([app1])
        end
      end

      context "when one application type code is provided" do
        let(:params) { {applicationType: ["ldc.existing"]} }

        it "returns matching applications" do
          expect(results).to match_array([app1])
        end
      end

      context "when multiple application type codes are provided" do
        let(:params) { {applicationType: ["ldc.existing", "pp.full.householder"]} }

        it "returns matching applications" do
          expect(results).to match_array([app1, app2, app3])
        end
      end

      context "when comma-separated application type codes are provided as a single string" do
        let(:params) { {applicationType: "ldc.existing,pp.full.householder"} }

        it "returns matching applications for both codes" do
          expect(results).to match_array([app1, app2, app3])
        end
      end

      context "when application type code is provided as a single string" do
        let(:params) { {applicationType: "ldc.existing"} }

        it "returns matching applications for both codes" do
          expect(results).to match_array([app1])
        end
      end

      context "when application type codes and query are provided" do
        let(:params) { {q: "Random street", applicationType: ["pp.full.householder"]} }

        it "returns matching applications" do
          expect(results).to match_array([app3])
        end
      end
    end

    context "when filtering by application status" do
      let(:local_authority) { create(:local_authority) }

      let!(:app1) { create(:planning_application, :in_assessment) }
      let!(:app2) { create(:planning_application, :to_be_reviewed) }

      context "when no application type codes are provided" do
        let(:params) { {applicationStatus: [""]} }

        it "returns all applications" do
          expect(results).to match_array([app1, app2])
        end
      end

      context "when one matching application type code is provided" do
        let(:params) { {applicationStatus: ["in_assessment", "notvalid"]} }

        it "returns matching applications" do
          expect(results).to include(app1)
          expect(results).not_to include(app2)
        end
      end

      context "when one application type code is provided" do
        let(:params) { {applicationStatus: ["in_assessment"]} }

        it "returns matching applications" do
          expect(results).to include(app1)
          expect(results).not_to include(app2)
        end
      end

      context "when multiple application type codes are provided" do
        let(:params) { {applicationStatus: ["in_assessment", "to_be_reviewed"]} }

        it "returns matching applications" do
          expect(results).to include(app1)
          expect(results).to include(app2)
        end
      end

      context "when comma-separated application type codes are provided as a single string" do
        let(:params) { {applicationStatus: "in_assessment,to_be_reviewed"} }

        it "returns matching applications for both codes" do
          expect(results).to include(app1)
          expect(results).to include(app2)
        end
      end

      context "when application type code is provided as a single string" do
        let(:params) { {applicationStatus: "in_assessment"} }

        it "returns matching applications for both codes" do
          expect(results).to include(app1)
          expect(results).not_to include(app2)
        end
      end
    end

    context "when sorting results" do
      let!(:older_app) { create(:planning_application, published_at: 3.days.ago) }
      let!(:newer_app) { create(:planning_application, published_at: 1.day.ago) }

      context "ascending order by publishedAt" do
        let(:params) { {sortBy: "publishedAt", orderBy: "asc"} }

        it "returns the oldest application first" do
          expect(results.first).to eq(older_app)
          expect(results.last).to eq(newer_app)
        end
      end

      context "descending order by publishedAt" do
        let(:params) { {sortBy: "publishedAt", orderBy: "desc"} }

        it "returns the newest application first" do
          expect(results.first).to eq(newer_app)
          expect(results.last).to eq(older_app)
        end
      end

      context "default order when orderBy not provided" do
        let(:params) { {sortBy: "publishedAt"} }

        it "defaults to descending order" do
          expect(results.first).to eq(newer_app)
        end
      end
    end

    context "when filtering by date ranges" do
      let!(:old) do
        create(:planning_application, :planning_permission, :consulting, received_at: 10.days.ago, validated_at: 8.days.ago, published_at: 6.days.ago)
      end
      let!(:mid) do
        create(:planning_application, :planning_permission, :consulting, received_at: 5.days.ago, validated_at: 4.days.ago, published_at: 3.days.ago)
      end
      let!(:new) do
        create(:planning_application, :planning_permission, :consulting, received_at: 1.day.ago, validated_at: 1.day.ago, published_at: 1.day.ago)
      end

      before do
        old.consultation.update(end_date: 12.days.ago)
        mid.consultation.update(end_date: 5.days.ago)
        new.consultation.update(end_date: 1.days.ago)
      end

      context "receivedAtFrom only" do
        let(:params) { {receivedAtFrom: 3.days.ago.to_date.iso8601} }

        it "returns applications received on or after the given date" do
          expect(results).to match_array([new])
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
            publishedAtFrom: 4.days.ago.to_date.iso8601,
            publishedAtTo: 1.day.ago.to_date.iso8601
          }
        end

        it "returns applications within the published date range" do
          expect(results).to match_array([mid, new])
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
        create(:planning_application, received_at: 5.days.ago, published_at: 5.days.ago, description: "A roof extension")
      end
      let!(:roof_b) do
        create(:planning_application, received_at: 3.days.ago, published_at: 3.days.ago, description: "A roof extension")
      end
      let!(:loft) do
        create(:planning_application, received_at: 3.days.ago, published_at: 3.days.ago, description: "A loft extension")
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
      let!(:old) { create(:planning_application, published_at: 5.days.ago) }
      let!(:mid) { create(:planning_application, published_at: 3.days.ago) }
      let!(:new) { create(:planning_application, published_at: 1.day.ago) }

      let(:params) do
        {
          publishedAtFrom: 3.days.ago.to_date.iso8601,
          sortBy: "publishedAt",
          orderBy: "asc"
        }
      end

      it "returns filtered and sorted results" do
        expect(results).to eq([mid, new])
      end
    end

    context "when filtering by decision" do
      let(:local_authority) { create(:local_authority) }

      let!(:app1) { create(:planning_application, :in_assessment) }
      let!(:app2) { create(:planning_application, :determined) }

      context "when no applicaton decisions are provided" do
        let(:params) { {councilDecision: nil} }

        it "returns matching applications" do
          expect(results).to match_array([app1, app2])
        end
      end

      context "when one matching application decision is provided" do
        let(:params) { {councilDecision: "granted"} }

        it "returns matching applications" do
          expect(results).to match_array([app2])
        end
      end
    end

    context "when filtering by alternative reference" do
      let!(:app_with_alt_ref) { create(:planning_application, alternative_reference: "ALT-REF-12345") }
      let!(:app_with_different_alt_ref) { create(:planning_application, alternative_reference: "OTHER-REF-99999") }
      let!(:app_without_alt_ref) { create(:planning_application, alternative_reference: nil) }

      context "when no alternative reference is provided" do
        let(:params) { {alternativeReference: nil} }

        it "returns all applications" do
          expect(results).to match_array([app_with_alt_ref, app_with_different_alt_ref, app_without_alt_ref])
        end
      end

      context "when alternative reference is provided" do
        let(:params) { {alternativeReference: "ALT-REF"} }

        it "returns matching applications (case-insensitive partial match)" do
          expect(results).to match_array([app_with_alt_ref])
        end
      end

      context "when alternative reference is provided with different case" do
        let(:params) { {alternativeReference: "alt-ref"} }

        it "returns matching applications (case-insensitive)" do
          expect(results).to match_array([app_with_alt_ref])
        end
      end

      context "when alternative reference does not match any application" do
        let(:params) { {alternativeReference: "NONEXISTENT"} }

        it "returns no applications" do
          expect(results).to be_empty
        end
      end
    end
  end
end
