import { application } from "./application"

import ClearFormController from "./clear_form_controller.js"
application.register("clear-form", ClearFormController)

import DeleteRecordController from "./delete_record_controller.js"
application.register("delete-record", DeleteRecordController)

import ShowHideController from "./show_hide_controller.js"
application.register("show-hide", ShowHideController)

import SubmitFormController from "./submit_form_controller.js"
application.register("submit-form", SubmitFormController)

import UnsavedChangesController from "./unsaved_changes_controller.js"
application.register("unsaved-changes", UnsavedChangesController)

window.addEventListener("DOMContentLoaded", () => {
  let pathname = window.location.pathname
  let scrollPositionKey = `${pathname}-scrollPosition`

  if (sessionStorage.getItem(scrollPositionKey)) {
    window.scrollTo(0, sessionStorage.getItem(scrollPositionKey))
  }

  window.onbeforeunload = function () {
    if (
      scrollPositionKey === "/-scrollPosition" ||
      scrollPositionKey === "/planning_applications-scrollPosition"
    ) {
      sessionStorage.setItem(scrollPositionKey, 0)
    } else {
      sessionStorage.setItem(scrollPositionKey, window.scrollY)
    }
  }
})
