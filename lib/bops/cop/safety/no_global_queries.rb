# frozen_string_literal: true

module Bops
  module Cop
    module Safety
      class NoGlobalQueries < RuboCop::Cop::Base
        def on_send(node)
          return unless node.receiver
          return unless node.receiver.source == "PlanningApplication"
          return unless %i[find_by find_by!
            find_or_create_by find_or_create_by!
            find_or_initialize_by
            find where count first last exists? any? all? none?].include? node.method_name

          add_offense(node.loc.selector, message: "Do not use #{node.method_name} directly on #{node.receiver.source}: scope it to a local authority")
        end
      end
    end
  end
end
