import { Controller } from "@hotwired/stimulus"
import { ajax } from "@rails/ujs"

export default class extends Controller {
  handleClick(event) {
    const dataset = event.currentTarget.dataset

    ajax({
      type: dataset["deleteRecordAction"] || "delete",
      url: dataset["deleteRecordPath"],
      success: (data) => { this.element.outerHTML = data.partial }
    })
  }
}
