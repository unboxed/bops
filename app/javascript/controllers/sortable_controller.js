import { Controller } from "@hotwired/stimulus"
import { put } from "@rails/request.js"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.initializeSortable()
  }

  disconnect() {
    this.sortable.destroy()
  }

  initializeSortable() {
    this.sortable = Sortable.create(this.element, {
      animation: 350,
      handle: "[data-sortable-handle]",
      onEnd: this.onEnd.bind(this),
    })
  }

  onEnd(event) {
    const { newIndex, item } = event
    const url = item.dataset.sortableUrl

    put(url, {
      body: JSON.stringify({
        informative: {
          position: newIndex,
        },
      }),
    })
      .then(() => {
        const modelName = item.dataset.modelName

        if (modelName) {
          this.updatePositions(modelName)
        }
      })
      .catch((error) => {
        console.error("Error updating position:", error)
      })
  }

  updatePositions(modelName) {
    const items = this.element.querySelectorAll("li")

    items.forEach((item, index) => {
      const positionElement = item.querySelector(".govuk-hint")
      if (positionElement) {
        positionElement.textContent = `${modelName} ${index + 1}`
      }
    })
  }
}
