# frozen_string_literal: true

module Bops
  module Cop
    module Style
      class UseGovukLinkHelper < RuboCop::Cop::Base
        extend ::RuboCop::Cop::AutoCorrector

        MSG = "Prefer `%<good_action>s` over `%<bad_action>s`."
        RESTRICT_ON_SEND = %i[link_to govuk_link_to govuk_button_link_to].freeze

        def on_send(node)
          hash_arg = node.arguments.select { _1.type == :hash }.first
          return if hash_arg.nil? || hash_arg.empty? # rubocop:disable Rails/Blank

          hash_arg.each_pair do |k, v|
            next unless k.value == :class

            classes = v.source

            if /\bgovuk-link\b/.match?(classes)
              build_replacement(node, classes,
                hash_arg:,
                class_name: "govuk-link", method_name: "govuk_link_to",
                params: {"govuk-link--muted" => "muted",
                         "govuk-link--no-underline" => "no_underline",
                         "govuk-link--no-visited-state" => "no_visited_state"})
            elsif /\bgovuk-button\b/.match?(classes)
              build_replacement(node, classes,
                hash_arg:, class_name: "govuk-button", method_name: "govuk_button_link_to",
                params: {"govuk-button--primary" => nil,
                         "govuk-button--secondary" => "secondary",
                         "govuk-button--warning" => "warning"})
            end
          end
        end

        private

        def build_replacement(node, classes, hash_arg:, class_name:, method_name:, params: {})
          add_offense(node.loc.selector, message: message(class_name:, method_name:)) do |corrector|
            if node.arguments.length == 3 && hash_arg.pairs.length == 1
              replacement = "#{method_name} #{node.arguments[0].source}, #{node.arguments[1].source}"

              replacement_classes = classes.gsub(/^['"]|['"]$/, "")
              replacement_classes.gsub!(/\b#{class_name}\b(?!-)/, "")

              params.each_pair do |subclass, keyword|
                pattern = /\b#{subclass}\b(?!-)/
                if pattern.match?(replacement_classes)
                  replacement_classes.gsub!(pattern, "").strip
                  replacement << ", #{keyword}: true" if keyword
                end
              end

              replacement_classes.strip!
              replacement << ", class: \"#{replacement_classes}\"" unless replacement_classes.blank?

              corrector.replace(node, replacement) if replacement
            end
          end
        end

        def message(class_name:, method_name:)
          format(MSG, good_action: "#{method_name} foo_path", bad_action: "link_to foo_path, class: \"#{class_name}\"")
        end
      end
    end
  end
end
