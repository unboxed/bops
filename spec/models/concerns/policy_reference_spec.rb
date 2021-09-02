require "rails_helper"

RSpec.describe PolicyReference, type: :model do
  let(:a1) { make_class_for_part("A", 1) }
  let(:a2) { make_class_for_part("A", 2) }

  subject(:application) { create(:planning_application) }

  def make_class_for_part(class_name, part_number)
    {
      "part" => part_number,
      "id" =>  class_name,
      "name" => "some policy class",
      "policies" => %w[one two three],
    }
  end

  describe "policy_classes=" do
    context "when there are no policy classes" do
      it "assigns them" do
        application.policy_classes = [a1]

        expect(application.policy_classes).to include a1
      end
    end

    context "when there is already a policy class" do
      before do
        application.policy_classes = [a1]
      end

      it "does not delete it" do
        application.policy_classes = [a2]

        expect(application.policy_classes).to include a1
      end

      it "keeps the previous classes" do
        application.policy_classes = [a2]

        expect(application.policy_classes).to include a2
      end
    end
  end
end
