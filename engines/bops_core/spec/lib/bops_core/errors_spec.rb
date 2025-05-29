# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::Errors do
  let(:public_path) { Pathname.new(Dir.mktmpdir) }

  after do
    FileUtils.remove_entry(public_path)
  end

  describe ".precompile" do
    %w[400 401 403 404 406 422 500 503].each do |error|
      context "#{error}.html" do
        subject { public_path.join("#{error}.html") }

        it "is generated" do
          expect {
            described_class.precompile(public_path)
          }.to change(subject, :exist?).from(false).to(true)
        end
      end
    end

    context "error.css" do
      subject { public_path.join("error.css") }

      it "is generated" do
        expect {
          described_class.precompile(public_path)
        }.to change(subject, :exist?).from(false).to(true)
      end
    end

    %w[400 400-italic 700 700-italic].each do |font|
      context "fonts/open-sans-#{font}.woff2" do
        subject { public_path.join("fonts/open-sans-#{font}.woff2") }

        it "is copied" do
          expect {
            described_class.precompile(public_path)
          }.to change(subject, :exist?).from(false).to(true)
        end
      end
    end
  end

  describe ".clobber" do
    before do
      described_class.precompile(public_path)
    end

    %w[400 401 403 404 406 422 500 503].each do |error|
      context "#{error}.html" do
        subject { public_path.join("#{error}.html") }

        it "is deleted" do
          expect {
            described_class.clobber(public_path)
          }.to change(subject, :exist?).from(true).to(false)
        end
      end
    end

    context "error.css" do
      subject { public_path.join("error.css") }

      it "is deleted" do
        expect {
          described_class.clobber(public_path)
        }.to change(subject, :exist?).from(true).to(false)
      end
    end

    %w[400 400-italic 700 700-italic].each do |font|
      context "fonts/open-sans-#{font}.woff2" do
        subject { public_path.join("fonts/open-sans-#{font}.woff2") }

        it "is copied" do
          expect {
            described_class.clobber(public_path)
          }.to change(subject, :exist?).from(true).to(false)
        end
      end
    end

    context "fonts" do
      subject { public_path.join("fonts") }

      it "is deleted" do
        expect {
          described_class.clobber(public_path)
        }.to change(subject, :exist?).from(true).to(false)
      end
    end
  end
end
