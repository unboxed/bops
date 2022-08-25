import { application } from "./application"

import ClearFormController from "./clear_form_controller.js"
application.register("clear-form", ClearFormController)

import UnsavedChangesController from "./unsaved_changes_controller.js"
application.register("unsaved-changes", UnsavedChangesController)
