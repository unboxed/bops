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
    const { oldIndex, newIndex, item } = event
    const url = item.dataset.sortableUrl
    const modelName = item.dataset.modelName

    if (oldIndex === newIndex) {
      return
    }

    const payload = {
      [modelName.toLowerCase()]: {
        position: newIndex,
      },
    }

    put(url, {
      body: JSON.stringify(payload),
    })
      .then(() => {
        this.updatePositions(modelName)
      })
      .catch((error) => {
        console.error("Error updating position:", error)
      })
  }

  updatePositions(modelName) {
    const items = document
      .querySelector('[data-controller="sortable"]')
      .querySelectorAll("li")

    items.forEach((item, index) => {
      const positionElement = item.querySelector(".govuk-caption-m")
      if (positionElement) {
        positionElement.textContent = `${modelName} ${index + 1}`
      }
    })
  }
}
