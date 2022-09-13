import { Controller } from "@hotwired/stimulus"
import { ajax } from "@rails/ujs"

export default class extends Controller {
  handleClick(event) {
    ajax({
      type: "delete",
      url: event.currentTarget.dataset["deleteRecordPath"],
      success: (data) => { this.element.outerHTML = data.partial }
    })
  }
}
