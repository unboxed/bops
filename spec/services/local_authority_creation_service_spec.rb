# frozen_string_literal: true

require "rails_helper"

RSpec.describe LocalAuthorityCreationService do
  describe "#call" do
    context "when user passes all available options" do
      let(:options) do
        {
          subdomain: "lambeth",
          council_code: "LBH",
          signatory_name: "Christina Thompson",
          signatory_job_title: "Director of Finance & Property",
          enquiries_paragraph: "Planning, London Borough of Lambeth, PO Box 734, Winchester SO23 5DG",
          email_address: "planning@lambeth.gov.uk",
          feedback_email: "feedback_email@lambeth.gov.uk",
          admin_email: "admin_email@lambeth.gov.uk"
        }
      end

      let(:service) do
        described_class.new(options)
      end

      it "creates the local authority" do
        expect { service.call }
          .to change(LocalAuthority, :count)
          .by(1)
      end

      it "creates the api_user" do
        expect { service.call }
          .to change(ApiUser, :count)
          .by(1)
      end

      it "creates the user" do
        expect { service.call }
          .to change(User, :count)
          .by(1)
      end
    end

    context "when user passes misses few options" do
      let(:options) do
        {
          subdomain: "lambeth",
          signatory_name: "Christina Thompson",
          signatory_job_title: "Director of Finance & Property",
          enquiries_paragraph: "Planning, London Borough of Lambeth, PO Box 734, Winchester SO23 5DG",
          email_address: "planning@lambeth.gov.uk",
          feedback_email: "feedback_email@lambeth.gov.uk"
        }
      end

      let(:service) do
        described_class.new(options)
      end

      it "raises validation error" do
        expect { service.call }
          .to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Council code can't be blank"
          )
      end
    end
  end
end
