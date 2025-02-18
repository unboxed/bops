# frozen_string_literal: true

class ApplicationTypeDocumentTags
  include StoreModel::Model

  TAG_GROUPS = %w[drawings evidence supporting_documents].freeze

  TAG_GROUPS.each do |name|
    attribute name.to_sym, :list, default: -> { [] }
  end

  TagGroup = Struct.new(:name, :selected_tags, :all_tags) do
    def tags
      selected_tags
    end

    def translated_tags
      selected_tags.map(&method(:translate_tag)).sort_by(&:itself)
    end

    def irrelevant_tags
      all_tags - selected_tags
    end

    def to_s
      name
    end

    def tag_list
      all_tags.map(&method(:build_tag_list)).sort_by(&:last)
    end

    def selected_tag_list
      selected_tags.map(&method(:build_tag_list)).sort_by(&:last)
    end

    def irrelevant_tag_list
      irrelevant_tags.map(&method(:build_tag_list)).sort_by(&:last)
    end

    private

    def translate_tag(tag)
      translation = I18n.t("document_tags.#{tag}")
      translation.is_a?(Hash) ? translation[:main] || tag : translation
    end

    def build_tag_list(tag)
      [tag, translate_tag(tag)]
    end
  end

  def tag_groups
    TAG_GROUPS.map(&method(:build_tag_group))
  end

  private

  def build_tag_group(name)
    TagGroup.new(name, attributes[name], Document.tags(name))
  end
end
