# frozen_string_literal: true

get "/map_proxy/(*path)", to: "map_proxy#proxy", as: "applicants_os_proxy"

mount BopsApplicants::Engine, at: "/", as: :bops_applicants
