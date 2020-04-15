# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "home/index.html.erb", type: :view do
  context 'when the user is signed in' do
    it "should allow signed-in user to view content" do
      #We can create tests for this once we figure out if the different users need different pages
    end
  end

  context 'when the user is not signed in' do
    it "should not allow anonymous user to view content" do
      expect(rendered).not_to match(/Welcome/)
    end
  end
end
