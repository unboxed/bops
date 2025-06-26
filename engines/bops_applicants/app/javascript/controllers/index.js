import { Application } from "@hotwired/stimulus"

const application = Application.start()
application.debug = false
window.Stimulus = application

import AddressFillController from "./address_fill_controller.js"

application.register("address-fill", AddressFillController)

import SiteNoticeController from "./site_notice_controller.js"

application.register("site-notice", SiteNoticeController)
