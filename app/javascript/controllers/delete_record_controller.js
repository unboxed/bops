import { Controller } from "@hotwired/stimulus"
import Rails from "@rails/ujs"

export default class extends Controller {
  handleClick(event) {
    const dataset = event.currentTarget.dataset

    Rails.ajax({
      type: dataset.deleteRecordAction || "delete",
      url: dataset.deleteRecordPath,
      success: (data) => {
        this.element.outerHTML = data.partial
      },
    })
  }
}
