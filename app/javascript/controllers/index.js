import { application } from "./application"

import ClearFormController from "./clear_form_controller.js"
application.register("clear-form", ClearFormController)

import DeleteRecordController from "./delete_record_controller.js"
application.register("delete-record", DeleteRecordController)

import ShowHideController from "./show_hide_controller.js"
application.register("show-hide", ShowHideController)

import UnsavedChangesController from "./unsaved_changes_controller.js"
application.register("unsaved-changes", UnsavedChangesController)
