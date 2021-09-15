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
      "policies" => [
        { id: "A.1/a", text: "do this" },
        { id: "A.2/a", text: "do that" },
      ]
    }
  end

  def assert_class_present(classes, klass)
    expect(classes).to include hash_including(
      "id" => klass["id"],
      "part" => klass["part"],
    )
  end

  describe "policy_classes=" do
    context "when there are no policy classes" do
      it "assigns them" do
        application.policy_classes = [a1]

        assert_class_present(application.policy_classes, a1)
      end

      it "marks the policy references as undetermined" do
        application.policy_classes = [a1]

        statuses = application.policy_classes.collect do |klass|
          klass["policies"].collect do |policy|
            policy["status"]
          end
        end

        expect(statuses.flatten.uniq).to eq ["undetermined"]
      end
    end

    context "when there is already a policy class" do
      before do
        application.policy_classes = [a1]
      end

      it "does not delete it" do
        application.policy_classes = [a2]

        assert_class_present(application.policy_classes, a2)
      end

      it "keeps the previous classes" do
        application.policy_classes = [a2]

        assert_class_present(application.policy_classes, a1)
      end
    end
  end

  describe "#find_policy_class" do
    before { application.policy_classes = [a2] }

    context "when there is a matching class" do
      it "returns it" do
        assert_class_present([application.find_policy_class(2, "A")], a2)
      end
    end

    context "when there is no match" do
      it "returns nil" do
        expect(application.find_policy_class(2, "B")).to be_nil
      end
    end
  end
end
