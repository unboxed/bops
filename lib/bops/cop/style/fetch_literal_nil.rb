# frozen_string_literal: true

module Bops
  module Cop
    module Style
      class NoFetchWithLiteralNilDefault < RuboCop::Cop::Base
        extend ::RuboCop::Cop::AutoCorrector

        MSG = "Prefer `%<good_action>s` over `%<bad_action>s`."
        RESTRICT_ON_SEND = %i[fetch].freeze

        def on_send(node)
          return unless node.method_name == :fetch
          return unless node.arguments.length == 2

          if node.arguments[1].type == :nil
            add_offense(node.loc.selector, message: message) do |corrector|
              corrector.replace(node, "#{node.receiver.source}[#{node.arguments[0].source}]")
            end
          end
        end

        private

        def message
          format(MSG, good_action: good_action, bad_action: bad_action)
        end

        def good_action
          %(foo[:bar])
        end

        def bad_action
          %(foo.fetch(:bar, nil))
        end
      end
    end
  end
end
