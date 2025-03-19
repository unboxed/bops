# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::PostsubmissionPagination, type: :service do
  let!(:consultation) { create(:consultation, :started) }
  let!(:neighbour) { create(:neighbour, source: "sent_comment", consultation:) }
  let!(:neighbour_responses) { create_list(:neighbour_response, 50, neighbour:) }

  let(:scope) { NeighbourResponse.all }
  let(:params) { {} } # Default empty params
  let(:service) { described_class.new(scope: scope, params: params) }

  describe "#call" do
    context "when no pagination parameters are provided" do
      it "defaults to the first page and default results per page" do
        pagy, paginated_scope = service.call

        expect(pagy.page).to eq(BopsApi::PostsubmissionPagination::DEFAULT_PAGE)
        expect(pagy.limit).to eq(BopsApi::PostsubmissionPagination::DEFAULT_MAXRESULTS)
        expect(paginated_scope.to_a).to eq(scope.limit(BopsApi::PostsubmissionPagination::DEFAULT_MAXRESULTS).to_a)
      end
    end

    context "when valid pagination parameters are provided" do
      let(:params) { {page: 2, resultsPerPage: 5} }

      it "paginates the results correctly" do
        pagy, paginated_scope = service.call

        expect(pagy.page).to eq(2)
        expect(pagy.limit).to eq(5)
        expect(paginated_scope).to eq(scope.offset(5).limit(5))
      end
    end

    context "when resultsPerPage exceeds the maximum limit" do
      let(:params) { {resultsPerPage: 100} }

      it "caps resultsPerPage to the maximum limit" do
        pagy, paginated_scope = service.call

        expect(pagy.limit).to eq(BopsApi::PostsubmissionPagination::MAXRESULTS_LIMIT)
        expect(paginated_scope.to_a).to eq(scope.limit(50).to_a)
      end
    end

    context "when invalid pagination parameters are provided" do
      let(:params) { {page: -1, resultsPerPage: -5} }

      it "defaults to the first page and default results per page" do
        pagy, paginated_scope = service.call

        expect(pagy.page).to eq(BopsApi::PostsubmissionPagination::DEFAULT_PAGE)
        expect(pagy.limit).to eq(BopsApi::PostsubmissionPagination::DEFAULT_MAXRESULTS)
        expect(paginated_scope.to_a).to eq(scope.limit(BopsApi::PostsubmissionPagination::DEFAULT_MAXRESULTS).to_a)
      end
    end

    context "when resultsPerPage is zero" do
      let(:params) { {resultsPerPage: 0} }

      it "defaults to the default results per page" do
        pagy, paginated_scope = service.call

        expect(pagy.limit).to eq(BopsApi::PostsubmissionPagination::DEFAULT_MAXRESULTS)
        expect(paginated_scope.to_a).to eq(scope.limit(BopsApi::PostsubmissionPagination::DEFAULT_MAXRESULTS).to_a)
      end
    end

    context "when page is zero" do
      let(:params) { {page: 0} }

      it "defaults to the first page" do
        pagy, paginated_scope = service.call

        expect(pagy.page).to eq(BopsApi::PostsubmissionPagination::DEFAULT_PAGE)
        expect(paginated_scope.to_a).to eq(scope.limit(BopsApi::PostsubmissionPagination::DEFAULT_MAXRESULTS).to_a)
      end
    end

    context "when the scope is empty" do
      let(:scope) { NeighbourResponse.none }

      it "returns an empty paginated scope" do
        pagy, paginated_scope = service.call

        expect(pagy.page).to eq(BopsApi::PostsubmissionPagination::DEFAULT_PAGE)
        expect(pagy.limit).to eq(BopsApi::PostsubmissionPagination::DEFAULT_MAXRESULTS)
        expect(paginated_scope).to be_empty
      end
    end
  end

  describe "#results_per_page" do
    it "returns the default results per page when no parameter is provided" do
      expect(service.send(:results_per_page)).to eq(BopsApi::PostsubmissionPagination::DEFAULT_MAXRESULTS)
    end

    it "returns the capped results per page when exceeding the maximum limit" do
      params[:resultsPerPage] = 100
      expect(service.send(:results_per_page)).to eq(BopsApi::PostsubmissionPagination::MAXRESULTS_LIMIT)
    end

    it "returns the default results per page when a negative value is provided" do
      params[:resultsPerPage] = -5
      expect(service.send(:results_per_page)).to eq(BopsApi::PostsubmissionPagination::DEFAULT_MAXRESULTS)
    end

    it "returns the default results per page when a string is provided" do
      params[:resultsPerPage] = "fifteen"
      expect(service.send(:results_per_page)).to eq(BopsApi::PostsubmissionPagination::DEFAULT_MAXRESULTS)
    end
  end

  describe "#page" do
    it "returns the default page when no parameter is provided" do
      expect(service.send(:page)).to eq(BopsApi::PostsubmissionPagination::DEFAULT_PAGE)
    end

    it "returns the default page when a negative value is provided" do
      params[:page] = -1
      expect(service.send(:page)).to eq(BopsApi::PostsubmissionPagination::DEFAULT_PAGE)
    end

    it "returns the default page when a string is provided" do
      params[:page] = "one"
      expect(service.send(:page)).to eq(BopsApi::PostsubmissionPagination::DEFAULT_PAGE)
    end

    it "returns the provided page when a valid value is provided" do
      params[:page] = 3
      expect(service.send(:page)).to eq(3)
    end
  end
end
