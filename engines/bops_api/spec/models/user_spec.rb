# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::User, type: :model do
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
        }.to raise_error(BopsApi::Errors::MissingFileDownloaderType)
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

      it_behaves_like "a file downloader", BopsApi::FileDownloaders::BasicAuthentication

      describe "validations" do
        before do
          subject.valid?
        end

        it "validates the presence of username" do
          expect(errors[:username]).to include("can't be blank")
        end

        it "validates the presence of password" do
          expect(errors[:password]).to include("can't be blank")
        end
      end
    end

    context "when the type is 'BearerAuthentication'" do
      let(:attributes) do
        {"type" => "BearerAuthentication"}
      end

      it_behaves_like "a file downloader", BopsApi::FileDownloaders::BearerAuthentication

      describe "validations" do
        before do
          subject.valid?
        end

        it "validates the presence of token" do
          expect(errors[:token]).to include("can't be blank")
        end
      end
    end

    context "when the type is 'HeaderAuthentication'" do
      let(:attributes) do
        {"type" => "HeaderAuthentication"}
      end

      it_behaves_like "a file downloader", BopsApi::FileDownloaders::HeaderAuthentication

      describe "validations" do
        before do
          subject.valid?
        end

        it "validates the presence of the header key" do
          expect(errors[:key]).to include("can't be blank")
        end

        it "validates the presence of the header value" do
          expect(errors[:value]).to include("can't be blank")
        end
      end
    end
  end
end
