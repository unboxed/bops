import { application } from "./application"

import AddressFillController from "./address_fill_controller.js"
application.register("address-fill", AddressFillController)

import ClearFormController from "./clear_form_controller.js"
application.register("clear-form", ClearFormController)

import DeleteRecordController from "./delete_record_controller.js"
application.register("delete-record", DeleteRecordController)

import EditFormController from "./edit_form_controller.js"
application.register("edit-form", EditFormController)

import PolygonSearchController from "./polygon_search_controller.js"
application.register("polygon-search", PolygonSearchController)

import RadiusSearchController from "./radius_search_controller.js"
application.register("radius-search", RadiusSearchController)

import ShowHideController from "./show_hide_controller.js"
application.register("show-hide", ShowHideController)

import SubmitFormController from "./submit_form_controller.js"
application.register("submit-form", SubmitFormController)

import UnsavedChangesController from "./unsaved_changes_controller.js"
application.register("unsaved-changes", UnsavedChangesController)
