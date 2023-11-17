# frozen_string_literal: true

module Bops
  module Cop
    module Style
      class HaveCurrentPathLiteral < RuboCop::Cop::Base
        MSG = "Prefer `%<good_expectation>s` over `%<bad_expectation>s`."
        RESTRICT_ON_SEND = %i[have_current_path].freeze

        def_node_matcher :on_have_current_path, <<~PATTERN
          (send nil? :have_current_path (send nil? $...))
        PATTERN

        def on_send(node)
          on_have_current_path(node) do |(helper)|
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
          format(MSG, good_expectation: good_expectation, bad_expectation: bad_expectation)
        end

        def good_expectation
          %[expect(page).to have_current_path("/posts")]
        end

        def bad_expectation
          %[expect(page).to have_current_path(posts_path)]
        end
      end
    end
  end
end
