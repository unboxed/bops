import { Application } from "@hotwired/stimulus"

const application = Application.start()
application.debug = false
window.Stimulus = application

import SiteNoticeController from "./site_notice_controller.js"
application.register("site-notice", SiteNoticeController)
