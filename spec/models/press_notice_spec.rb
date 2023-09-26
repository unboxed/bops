# frozen_string_literal: true

require "rails_helper"

RSpec.describe PressNotice do
  describe "validations" do
    subject(:press_notice) { described_class.new }

    describe "#planning_application" do
      it "validates presence" do
        expect { press_notice.valid? }.to change { press_notice.errors[:planning_application] }.to ["must exist"]
      end
    end

    describe "#required" do
      it "validates inclusion in [true, false]" do
        expect { press_notice.valid? }.to change { press_notice.errors[:required] }.to ["You must choose 'Yes' or 'No'"]
      end
    end

    describe "#reasons" do
      context "when required is 'true'" do
        subject(:press_notice) { described_class.new(required: true) }

        it "validates presence" do
          expect { press_notice.valid? }.to change { press_notice.errors[:reasons] }.to ["You must provide a reason for the press notice"]
        end
      end

      context "when required is 'false'" do
        subject(:press_notice) { described_class.new(required: false) }

        it "does not validate presence" do
          expect { press_notice.valid? }.not_to(change { press_notice.errors[:reasons] })
        end
      end
    end

    describe "class methods" do
      describe "#reasons_list" do
        it "returns the reasons for press notice" do
          expect(described_class.reasons_list).to eq(
            { conservation_area: ["The site of the application is within/affecting the setting of a designated Conservation Area (Section 73) of the Planning (Listed Buildings and Conservation Areas) Act 1990"],
              listed_building: ["The application relates to, or affects the setting of a Listed Building (Section 67) of the Planning (Listed Buildings and Conservation Areas) Act 1990"],
              major_development: ["The application is for a Major Development"],
              wildlife_and_countryside: ["The application would affect a right of way to which Part III of the Wildlife and Countryside Act 1981 (as amended) applies"],
              development_plan: ["The application does not accord with the provisions of the development plan"],
              environment: ["An environmental statement accompanies this application"],
              ancient_monument: ["The site of the application is affecting the setting of an Ancient Monument"],
              public_interest: ["Wider Public interest"] }
          )
        end
      end

      describe "#reason_keys" do
        it "returns the reason types for press notice" do
          expect(described_class.reason_keys).to eq(
            %i[conservation_area
               listed_building
               major_development
               wildlife_and_countryside
               development_plan
               environment
               ancient_monument
               public_interest]
          )
        end
      end
    end

    describe "callbacks" do
      describe "::after_save #audit_press_notice!" do
        let(:default_local_authority) { create(:local_authority, :default) }
        let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
        let!(:planning_application) { create(:planning_application, local_authority: default_local_authority) }

        before do
          Current.user = assessor
        end

        context "when reasons is present" do
          let(:press_notice) { create(:press_notice, :required, planning_application:) }

          it "adds an audit entry with the reasons when creating the press notice response" do
            expect do
              press_notice
            end.to change(Audit, :count).by(1)

            expect(Audit.last).to have_attributes(
              planning_application_id: planning_application.id,
              activity_type: "press_notice",
              audit_comment: "Press notice has been marked as required with the following reasons: An environmental statement accompanies this application, The application does not accord with the provisions of the development plan",
              user: assessor
            )
          end

          it "adds an audit entry with the reasons when updating the press notice response" do
            press_notice

            expect do
              press_notice.update!(reasons: { ancient_monument: "The site of the application is affecting the setting of an Ancient Monument" })
            end.to change(Audit, :count).by(1)

            expect(Audit.last).to have_attributes(
              planning_application_id: press_notice.planning_application.id,
              activity_type: "press_notice",
              audit_comment: "Press notice has been marked as required with the following reasons: The site of the application is affecting the setting of an Ancient Monument",
              user: assessor
            )
          end
        end

        context "when reasons is not present" do
          let(:press_notice) { create(:press_notice, planning_application:) }

          it "adds an audit entry when creating the press notice response" do
            expect do
              press_notice
            end.to change(Audit, :count).by(1)

            expect(Audit.last).to have_attributes(
              planning_application_id: planning_application.id,
              activity_type: "press_notice",
              audit_comment: "Press notice has been marked as not required",
              user: assessor
            )
          end
        end
      end
    end
  end
end
