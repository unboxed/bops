# frozen_string_literal: true

module Bops
  module Cop
    module Style
      class VisitLiteral < RuboCop::Cop::Base
        MSG = "Prefer `%<good_action>s` over `%<bad_action>s`."
        RESTRICT_ON_SEND = %i[visit].freeze

        def_node_matcher :on_visit, <<~PATTERN
          (send nil? :visit (send nil? $...))
        PATTERN

        def on_send(node)
          on_visit(node) do |(helper)|
            unless helper_ignored?(helper)
              add_offense(node.loc.selector, message: message)
            end
          end
        end

        private

        def helper_ignored?(helper)
          Array(cop_config["IgnoreHelpers"]).include?(helper.to_s)
        end

        def message
          format(MSG, good_action: good_action, bad_action: bad_action)
        end

        def good_action
          %(visit "/posts")
        end

        def bad_action
          %(visit posts_path)
        end
      end
    end
  end
end
