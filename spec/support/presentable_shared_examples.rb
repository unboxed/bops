# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "Presentable" do
  it "delegates missing methods to presented record" do
    expect(presenter.id).to eq(presented.id)
  end

  it "advertises the methods it responds to" do
    expect(presenter).to respond_to(:id)
  end

  it "delegates #to_param to presented record" do
    expect(presenter.to_param).to eq(presented.to_param)
  end
end
