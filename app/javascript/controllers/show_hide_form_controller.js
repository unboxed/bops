import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  handleEvent(event) {
    console.log("hi there")
    if(event.target.value == "yes") {
      if(!document.getElementById("site-notice-form-actions").classList.contains("display-none")) {
        document.getElementById("site-notice-form-actions").classList.add("display-none")
      }

      document.getElementById("site-notice-options").classList.remove("display-none")
    } else if((event.target.value == "no")) {
      if(!document.getElementById("site-notice-options").classList.contains("display-none")) {
        document.getElementById("site-notice-options").classList.add("display-none")
      }

      document.getElementById("site-notice-form-actions").classList.remove("display-none")
    }
  }
}
