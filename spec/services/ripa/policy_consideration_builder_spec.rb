# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ripa::PolicyConsiderationBuilder do
  describe ".import" do
    subject(:builder) { described_class.new(json) }

    context "when passed an empty hash" do
      let(:json) { {}.to_json }

      it "returns an empty array" do
        expect(builder.import).to eq []
      end
    end

    context "when passed a hash without expected keys" do
      let(:json) do
        {
          flow: [
            {

            },
          ],
        }.to_json
      end

      it "returns an empty array" do
        expect(builder.import).to eq []
      end
    end

    context "when passed a hash containing a single policy question and answer" do
      let(:json) do
        {
          flow: [
            {
              text: "The property is",
              options: [
                {
                  id: "-LsXty7cOZycK0rqv8B3",
                  text: "a detached house",
                },
                {
                  id: "-LsXty7cOZycK0rqv8B5",
                  text: "a semi detached house",
                },
              ],
              choice: {
                id: "-LsXty7cOZycK0rqv8B5",
              },
            },
          ],
        }.to_json
      end

      it "returns an array containing a single PolicyConsideration instance" do
        policy_considerations = builder.import

        expect(policy_considerations.count).to eq 1

        policy_consideration = policy_considerations.first

        expect(policy_consideration.policy_question).to eq "The property is"
        expect(policy_consideration.applicant_answer).to eq "a semi detached house"
      end
    end

    context "when passed a hash containing multiple policy questions and answers" do
      let(:json) do
        {
          flow: [
            {
              text: "The property is",
              options: [
                {
                  id: "-LsXty7cOZycK0rqv8B3",
                  text: "a detached house",
                },
                {
                  id: "-LsXty7cOZycK0rqv8B5",
                  text: "a semi detached house",
                },
              ],
              choice: {
                id: "-LsXty7cOZycK0rqv8B5",
              },
            },
            {
              text: "I want to",
              options: [
                {
                  id: "-LsXty7cOZycK0rqv8B1",
                  text: "modify or extend",
                },
                {
                  id: "-LsXty7cOZycK0rqv8Bo",
                  text: "build new",
                },
              ],
              choice: {
                id: "-LsXty7cOZycK0rqv8Bo",
              },
            },
          ],
        }.to_json
      end

      it "returns an array containing multiple PolicyConsideration instances" do
        policy_considerations = builder.import

        expect(policy_considerations.count).to eq 2

        policy_consideration_1 = policy_considerations.first

        expect(policy_consideration_1.policy_question).to eq "The property is"
        expect(policy_consideration_1.applicant_answer).to eq "a semi detached house"

        policy_consideration_2 = policy_considerations.second

        expect(policy_consideration_2.policy_question).to eq "I want to"
        expect(policy_consideration_2.applicant_answer).to eq "build new"
      end
    end

    context "when passed a hash containing multiple policy questions, containing some without an answer" do
      let(:json) do
        {
          flow: [
            {
              text: "The property is",
              options: [
                {
                  id: "-LsXty7cOZycK0rqv8B3",
                  text: "a detached house",
                },
                {
                  id: "-LsXty7cOZycK0rqv8B5",
                  text: "a semi detached house",
                },
              ],
              choice: {
                # NO CHOICE HERE
              },
            },
            {
              text: "I want to",
              options: [
                {
                  id: "-LsXty7cOZycK0rqv8B1",
                  text: "modify or extend",
                },
                {
                  id: "-LsXty7cOZycK0rqv8Bo",
                  text: "build new",
                },
              ],
              choice: {
                id: "-LsXty7cOZycK0rqv8Bo",
              },
            },
          ],
        }.to_json
      end

      it "returns an array containing the only PolicyConsideration instance with an applicant choice" do
        policy_considerations = builder.import

        expect(policy_considerations.count).to eq 1

        policy_consideration_1 = policy_considerations.first

        expect(policy_consideration_1.policy_question).to eq "I want to"
        expect(policy_consideration_1.applicant_answer).to eq "build new"
      end
    end
  end
end
