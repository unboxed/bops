import { application } from "./application"

import ConditionsController from "./conditions_controller.js"
application.register("conditions", ConditionsController)

import AddressFillController from "./address_fill_controller.js"
application.register("address-fill", AddressFillController)

import ConsulteesController from "./consultees_controller.js"
application.register("consultees", ConsulteesController)

import ConsulteeEmailController from "./consultee_email_controller.js"
application.register("consultee-email", ConsulteeEmailController)

import ClearFormController from "./clear_form_controller.js"
application.register("clear-form", ClearFormController)

import DeleteRecordController from "./delete_record_controller.js"
application.register("delete-record", DeleteRecordController)

import EditFormController from "./edit_form_controller.js"
application.register("edit-form", EditFormController)

import PdfController from "./pdf_controller"
application.register("pdf", PdfController)

import PolygonSearchController from "./polygon_search_controller.js"
application.register("polygon-search", PolygonSearchController)

import ShowHideController from "./show_hide_controller.js"
application.register("show-hide", ShowHideController)

import ShowHideFormController from "./show_hide_form_controller.js"
application.register("show-hide-form", ShowHideFormController)

import ShowMoreTextController from "./show_more_text_controller.js"
application.register("show-more-text", ShowMoreTextController)

import SubmitFormController from "./submit_form_controller.js"
application.register("submit-form", SubmitFormController)

import UnsavedChangesController from "./unsaved_changes_controller.js"
application.register("unsaved-changes", UnsavedChangesController)

import ResetTextController from "./reset_text_controller.js"
application.register("reset-text", ResetTextController)
