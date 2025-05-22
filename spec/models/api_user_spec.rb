# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiUser do
  describe "#validations" do
    it "creates api user successfully" do
      api_user = create(:api_user, permissions: %w[validation_request:read])
      expect(api_user).to be_valid
    end

    it "generates a new client secret" do
      api_user = build(:api_user)
      api_user.save

      expect(api_user.token).not_to be_empty
    end

    it "is not created without a name" do
      api_user = build(:api_user, name: nil)
      expect(api_user).not_to be_valid
    end

    it "must have a unique name and token" do
      create(:api_user, permissions: %w[validation_request:read], name: "test")
      api_user = build(:api_user, name: "test")
      api_user.save

      expect(api_user.errors[:name]).to include("That name is already in use by an active token")
    end

    it "must have a token in the correct format" do
      api_user = build(:api_user, token: "token")
      expect(api_user).not_to be_valid
    end
  end

  describe "#file_downloader" do
    let(:file_downloader) { subject.file_downloader }
    let(:errors) { file_downloader.errors }

    subject { described_class.new(file_downloader: attributes) }

    context "when the type isn't specified" do
      let(:attributes) do
        {}
      end

      it "raises an error" do
        expect {
          file_downloader
        }.to raise_error(ArgumentError, "Missing file downloader type")
      end
    end

    shared_examples "a file downloader" do |klass|
      it "returns an instance of the correct type" do
        expect(file_downloader).to be_an_instance_of(klass)
      end

      it "defaults to an open timeout of 5 seconds" do
        expect(file_downloader).to have_attributes(open_timeout: 5)
      end

      it "allows overidding the open timeout" do
        file_downloader.assign_attributes(open_timeout: 10)
        expect(file_downloader).to have_attributes(open_timeout: 10)
      end

      it "defaults to an read timeout of 5 seconds" do
        expect(file_downloader).to have_attributes(read_timeout: 5)
      end

      it "allows overidding the read timeout" do
        file_downloader.assign_attributes(read_timeout: 10)
        expect(file_downloader).to have_attributes(read_timeout: 10)
      end
    end

    context "when the type is 'BasicAuthentication'" do
      let(:attributes) do
        {"type" => "BasicAuthentication"}
      end

      it_behaves_like "a file downloader", FileDownloaders::BasicAuthentication

      describe "validations" do
        before do
          subject.valid?
        end

        it "validates the presence of username" do
          expect(errors[:username]).to include("Please enter the username")
        end

        it "validates the presence of password" do
          expect(errors[:password]).to include("Please enter the password")
        end
      end
    end

    context "when the type is 'BearerAuthentication'" do
      let(:attributes) do
        {"type" => "BearerAuthentication"}
      end

      it_behaves_like "a file downloader", FileDownloaders::BearerAuthentication

      describe "validations" do
        before do
          subject.valid?
        end

        it "validates the presence of token" do
          expect(errors[:token]).to include("Please enter the bearer token value")
        end
      end
    end

    context "when the type is 'HeaderAuthentication'" do
      let(:attributes) do
        {"type" => "HeaderAuthentication"}
      end

      it_behaves_like "a file downloader", FileDownloaders::HeaderAuthentication

      describe "validations" do
        before do
          subject.valid?
        end

        it "validates the presence of the header key" do
          expect(errors[:key]).to include("Please enter the name of the custom header")
        end

        it "validates the presence of the header value" do
          expect(errors[:value]).to include("Please enter the value for the custom header")
        end
      end
    end
  end

  describe ".authenticate" do
    let(:token) { "bops_xjqhZoM8AmM2ptLkNdGA4uY5Y8j1qoq1MHHwVTt-Mg" }

    around do |example|
      freeze_time { example.run }
    end

    context "when an API user with the token exists" do
      let!(:api_user) { create(:api_user, permissions: %w[validation_request:read], token:) }

      it "returns the API user" do
        expect(described_class.authenticate(token)).to eq(api_user)
      end

      it "updates the last_used_at timestamp" do
        expect {
          described_class.authenticate(token)
        }.to change {
          api_user.reload.last_used_at
        }.from(nil).to(Time.current)
      end
    end

    context "when an API user with the token doesn't exist" do
      it "returns nil" do
        expect(described_class.authenticate(token)).to be_nil
      end
    end
  end

  describe ".generate_unique_secure_token" do
    let(:pattern) { described_class::TOKEN_FORMAT }
    let(:token) { described_class.generate_unique_secure_token }
    let(:checksum) { Zlib.crc32(token[5..40]) }
    let(:decoded_checksum) { Base64.urlsafe_decode64(token[41..46]).unpack1("L") }

    it "generates tokens in the correct format" do
      expect(token).to match(pattern)
    end

    it "generates tokens with a valid checksum" do
      expect(checksum).to eq(decoded_checksum)
    end
  end

  describe ".valid_token?" do
    it "returns true for a valid token" do
      token = "bops_KpR5kYmDcMikbj9dX7HkEk2xYvFfVbMn78H8clkQvw"
      expect(described_class.valid_token?(token)).to eq(true)
    end

    it "returns false for a token in the incorrect format" do
      token = "bops_InvalidToken"
      expect(described_class.valid_token?(token)).to eq(false)
    end

    it "returns false for a token with an invalid checksum" do
      token = "bops_eGfQ2ynJUPgzURvcMhGHSvArwKf412sqvKgcXxXxXx"
      expect(described_class.valid_token?(token)).to eq(false)
    end
  end
end
