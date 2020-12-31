# frozen_string_literal: true

class DocumentNumbersListForm
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_reader :documents

  def initialize(documents, documents_numbers_hash = {})
    @documents = documents.map { |document| DocumentNumbersUpdateForm.new(document) }
    @documents_numbers_hash = documents_numbers_hash
  end

  def update_all
    ActiveRecord::Base.transaction do
      documents.each do |document|
        document.numbers = documents_numbers_hash.dig(document.id.to_s, "numbers")
        document.save!
      end

      raise ActiveRecord::Rollback if any_documents_errors?
    end

    !any_documents_errors?
  end

private

  attr_accessor :documents_numbers_hash

  def any_documents_errors?
    documents.map(&:errors).any?(&:present?)
  end

  class DocumentNumbersUpdateForm
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :document

    validates :numbers, presence: { message: "Provide at least one number" }

    delegate(*Document.attribute_names, to: :document)

    def initialize(document)
      @document = document
    end

    def file
      document.file
    end

    def name
      document.name
    end

    def numbers=(value)
      document.numbers = value
    end

    def numbers
      document.numbers
    end

    def save
      if valid?
        @document.update!(numbers: numbers)
      end

      errors.none?
    end
  end
end
