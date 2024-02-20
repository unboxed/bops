# frozen_string_literal: true

class CreateReviewsForOwnershipCertificates < ActiveRecord::Migration[7.1]
  def change
    OwnershipCertificate.all.find_each do |certificate|
      next if certificate.reviews.any?

      Review.create!(owner_type: "OwnershipCertificate", owner_id: certificate.id, status: "not_started")
    end
  end
end
