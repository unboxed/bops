# frozen_string_literal: true

module BopsCore
  module FormElements
    class RichTextArea < GOVUKDesignSystemFormBuilder::Base
      using GOVUKDesignSystemFormBuilder::PrefixableArray

      include GOVUKDesignSystemFormBuilder::Traits::Error
      include GOVUKDesignSystemFormBuilder::Traits::Hint
      include GOVUKDesignSystemFormBuilder::Traits::Label
      include GOVUKDesignSystemFormBuilder::Traits::Supplemental
      include GOVUKDesignSystemFormBuilder::Traits::HTMLAttributes
      include GOVUKDesignSystemFormBuilder::Traits::HTMLClasses

      def initialize(builder, object_name, attribute_name, hint:, label:, caption:, form_group:, **kwargs, &)
        super(builder, object_name, attribute_name, &)

        @label = label
        @caption = caption
        @hint = hint
        @form_group = form_group
        @html_attributes = kwargs
      end

      def html
        GOVUKDesignSystemFormBuilder::Containers::FormGroup.new(*bound, **@form_group).html do
          safe_join([label_element, supplemental_content, hint_element, error_element, rich_text_area])
        end
      end

      private

      def bops_uploads
        BopsUploads::Engine.routes.url_helpers
      end

      def blob_url_template
        bops_uploads.file_path(":key:")
      end

      def direct_upload_url
        bops_uploads.uploads_path
      end

      def rich_text_area
        tag.div(class: classes, data: {controller: "rich-text"}) do
          @builder.rich_text_area(@attribute_name,
            data: {
              direct_upload_url:,
              blob_url_template:
            },
            **attributes(@html_attributes))
        end
      end

      def classes
        build_classes(%(rich-textarea), %(rich-textarea--error) => has_errors?).prefix("bops")
      end

      def options
        {
          id: field_id(link_errors: true),
          aria: {describedby: combine_references(hint_id, error_id, supplemental_id)}
        }
      end
    end
  end
end
