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

    this.addDragEventListeners()
  }

  onEnd(event) {
    const { oldIndex, newIndex, item } = event
    if (oldIndex === newIndex) return

    const url = item.dataset.sortableUrl
    const modelName = item.dataset.modelName

    put(url, {
      body: { position: newIndex + 1 },
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

  addDragEventListeners() {
    const sortableItems = this.element.querySelectorAll(".sortable-list")

    sortableItems.forEach((item) => {
      item.addEventListener("dragstart", this.onDragStart)
      item.addEventListener("dragend", this.onDragEnd)
    })
  }

  onDragStart(event) {
    event.target.classList.add("sortable-dragging-list")
    const svgElement = event.target.querySelector("svg")
    if (svgElement) {
      svgElement.classList.remove("sortable-svg")
      svgElement.classList.add("sortable-dragging-svg")
    }
  }

  onDragEnd(event) {
    event.target.classList.remove("sortable-dragging-list")
    const svgElement = event.target.querySelector("svg")
    if (svgElement) {
      svgElement.classList.remove("sortable-dragging-svg")
      svgElement.classList.add("sortable-svg")
    }
  }
}
