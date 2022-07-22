import { application } from "./application"

import SearchController from "./search_controller.js"
application.register("search", SearchController)

import UnsavedChangesController from "./unsaved_changes_controller.js"
application.register("unsaved-changes", UnsavedChangesController)
