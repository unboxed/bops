# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteNotice do
  describe "validations" do
    subject(:site_notice) { described_class.new }

    describe "#planning_application" do
      it "validates presence" do
        expect { site_notice.valid? }.to change { site_notice.errors[:planning_application] }.to ["must exist"]
      end
    end

    describe "#required" do
      it "validates inclusion in [true, false]" do
        expect { site_notice.valid? }.to change { site_notice.errors[:required] }.to ["Choose 'Yes' or 'No'"]
      end
    end

    describe "#quantity" do
      subject(:site_notice) { build(:site_notice, quantity:) }

      context "when blank" do
        let(:quantity) { nil }

        it "validates presence" do
          expect { site_notice.valid? }.to change { site_notice.errors[:quantity] }
            .to(include("Enter the number of site notices required"))
        end
      end

      context "when not an integer" do
        let(:quantity) { 1.5 }

        it "validates integer value" do
          expect { site_notice.valid? }.to change { site_notice.errors[:quantity] }
            .to(["Enter the number of site notices as a whole number"])
        end
      end

      context "when less than 1" do
        let(:quantity) { 0 }

        it "validates minimum value" do
          expect { site_notice.valid? }.to change { site_notice.errors[:quantity] }
            .to(["Number of site notices must be 1 or more"])
        end
      end
    end

    describe "#displayed_at" do
      let(:planning_application) { create(:planning_application, consultation:) }
      let(:consultation) { create(:consultation) }

      before do
        site_notice.planning_application = planning_application
        travel_to 1.day.from_now do
          planning_application.consultation.start_deadline
        end
      end

      it "validates date is not in future" do
        site_notice.displayed_at = 1.day.from_now

        expect { site_notice.valid?(:confirmation) }.to change { site_notice.errors[:displayed_at] }.to ["The date the site notice was displayed must be on or before today"]
      end

      it "validates date may be in past" do
        site_notice.displayed_at = 1.day.ago
        expect { site_notice.valid?(:confirmation) }.not_to change { site_notice.errors[:displayed_at] }
      end

      it "validates date may be today" do
        site_notice.displayed_at = Time.zone.now
        expect { site_notice.valid?(:confirmation) }.not_to change { site_notice.errors[:displayed_at] }
      end

      it "validates date may be before consultation start date" do
        site_notice.displayed_at = 1.day.ago

        expect(site_notice.displayed_at).to be < site_notice.planning_application.consultation.start_date

        expect { site_notice.valid?(:confirmation) }.not_to change { site_notice.errors[:displayed_at] }
      end
    end

    describe "callbacks" do
      describe "::before_create #ensure_publicity_feature!" do
        context "when the application type enables publicity" do
          let(:application_type) { create(:application_type, :planning_permission) }
          let(:planning_application) { create(:planning_application, application_type:) }
          let(:site_notice) { create(:site_notice, planning_application:) }

          it "allows a site notice to be created" do
            expect do
              site_notice
            end.not_to raise_error
          end
        end

        context "when the application type does not enable publicity" do
          let(:application_type) { create(:application_type, :without_consultation) }
          let(:planning_application) { create(:planning_application, application_type:) }
          let(:site_notice) { create(:site_notice, planning_application:) }

          it "allows a site notice to be created" do
            expect do
              site_notice
            end.to raise_error(described_class::NotCreatableError,
              "Cannot create site notice when application type does not permit this feature.")
          end
        end
      end

      describe "::after_update #extend_consultation!" do
        let(:default_local_authority) { create(:local_authority, :default) }
        let!(:planning_application) { create(:planning_application, :planning_permission, local_authority: default_local_authority) }
        let!(:consultation) { planning_application.consultation }
        let(:site_notice) { create(:site_notice, planning_application:) }

        context "when there is an update to the displayed_at date" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 3, 28, 23, 59, 59, 999999)
            )
          end

          it "there is an update of 21 days added to the consultation end date" do
            expect do
              site_notice.update(displayed_at: Time.zone.local(2023, 3, 15))
            end.to change(consultation, :end_date)
              .from(Time.zone.local(2023, 3, 28).to_date)
              .to(Time.zone.local(2023, 4, 5).to_date)
          end

          it "sets the expiry date to the new consultation end date" do
            expect do
              site_notice.update(displayed_at: Time.zone.local(2023, 3, 15))
            end.to change(site_notice, :expiry_date)
              .from(nil)
              .to(Time.zone.local(2023, 4, 5).to_date)
          end
        end

        context "when there is an update to another field" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 3, 28, 23, 59, 59, 999999)
            )
          end

          it "there is no update to the consultation end date" do
            expect { site_notice.update(content: "bla") }.not_to change(consultation, :end_date)
          end

          it "does not update the expiry date" do
            expect { site_notice.update(content: "bla") }.not_to change(site_notice, :expiry_date).from(nil)
          end
        end

        context "when consultation end date is later than the displayed at date + 21 days" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 4, 10, 23, 59, 59, 999999)
            )
          end

          it "there is no update to the consultation end date" do
            expect { site_notice.update(displayed_at: Time.zone.local(2023, 3, 15)) }.not_to change(consultation, :end_date)
          end

          it "sets the expiry date to the existing consultation end date" do
            expect do
              site_notice.update(displayed_at: Time.zone.local(2023, 3, 15))
            end.to change(site_notice, :expiry_date)
              .from(nil)
              .to(consultation.end_date)
          end
        end

        context "when consultation end date is less than the displayed at date + 21 days" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 3, 28, 23, 59, 59, 999999)
            )
          end

          it "there is an update to the consultation end date" do
            expect do
              site_notice.update(displayed_at: Time.zone.local(2023, 3, 15))
            end.to change(consultation, :end_date)
              .from(Time.zone.local(2023, 3, 28).to_date)
              .to(Time.zone.local(2023, 4, 5).to_date)
          end

          it "sets the expiry date to the new consultation end date" do
            expect do
              site_notice.update(displayed_at: Time.zone.local(2023, 3, 15))
            end.to change(site_notice, :expiry_date)
              .from(nil)
              .to(Time.zone.local(2023, 4, 5).to_date)
          end
        end

        context "when application has been marked as requiring an EIA and there is an update to the displayed_at date" do
          let!(:environment_impact_assessment) { create(:environment_impact_assessment, planning_application:) }

          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 3, 28, 23, 59, 59, 999999)
            )
          end

          it "there is an update of 30 days added to the consultation end date" do
            expect do
              site_notice.update(displayed_at: Time.zone.local(2023, 3, 15))
            end.to change(consultation, :end_date)
              .from(Time.zone.local(2023, 3, 28).to_date)
              .to(Time.zone.local(2023, 4, 14).to_date)
          end

          it "sets the expiry date to the new consultation end date" do
            expect do
              site_notice.update(displayed_at: Time.zone.local(2023, 3, 15))
            end.to change(site_notice, :expiry_date)
              .from(nil)
              .to(Time.zone.local(2023, 4, 14).to_date)
          end
        end
      end
    end
  end
end
