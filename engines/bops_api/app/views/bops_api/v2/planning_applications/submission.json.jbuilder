# frozen_string_literal: true

json.key_format! camelize: :lower

json.partial! "bops_api/v2/shared/application", planning_application: @planning_application

json.submission @submission
