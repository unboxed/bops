# frozen_string_literal: true

module Bops
  module Cop
    module Style
      class UseGovukLinkHelper < RuboCop::Cop::Base
        extend ::RuboCop::Cop::AutoCorrector

        MSG = "Prefer `%<good_action>s` over `%<bad_action>s`."
        RESTRICT_ON_SEND = %i[link_to].freeze

        def on_send(node)
          return unless node.method_name == :link_to

          hash_arg = node.arguments.select { _1.type == :hash }.first
          return if hash_arg.nil? || hash_arg.empty? # rubocop:disable Rails/Blank

          hash_arg.each_pair do |k, v|
            next unless k.value == :class

            classes = v.source
            next unless /\bgovuk-link\b/.match?(classes)

            add_offense(node.loc.selector, message: message) do |corrector|
              if node.arguments.length == 3 && hash_arg.pairs.length == 1
                replacement = "govuk_link_to #{node.arguments[0].source}, #{node.arguments[1].source}"
                replacement_classes = classes.sub(/\bgovuk-link\b/, "").strip
                replacement_classes.gsub!(/^('|") /, '\1')
                replacement_classes.gsub!(/ ('|")$/, '\1')
                replacement << ", class: #{replacement_classes}" unless replacement_classes == '""'

                corrector.replace(node, replacement)
              end
            end
          end
        end

        private

        def message
          format(MSG, good_action: good_action, bad_action: bad_action)
        end

        def good_action
          %(govuk_link_to foo_path)
        end

        def bad_action
          %(link_to foo_path, class: "govuk-link")
        end
      end
    end
  end
end
