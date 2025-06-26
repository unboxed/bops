import { Controller } from "@hotwired/stimulus"
import JSZip from "jszip"

export default class extends Controller {
  static targets = ["documentsElement", "button"]
  static values = {
    applicationReference: String,
    documentTitle: String,
    documentUrl: String,
  }

  async submit(event) {
    event.preventDefault()
    this.clearError()
    this.showLoadingSpinner()
    const applicationReference = this.element.dataset.applicationReferenceValue
    const documents = this.documentsElementTarget.querySelectorAll("li")
    const zip = new JSZip()

    try {
      documents.forEach((document) => {
        const imageDownload = document.dataset.documentUrlValue
        const file = fetch(imageDownload).then((r) => r.blob())

        const fileName = document.dataset.documentTitleValue

        zip.file(fileName, file)
      })

      const folder = await zip.generateAsync({ type: "blob" })
      saveAs(folder, applicationReference)
    } catch (error) {
      console.error("Failure to download:", error)
      this.showError(error)
    } finally {
      this.hideLoadingSpinner()
    }
  }

  showLoadingSpinner() {
    const spinner = document.createElement("div")
    spinner.className = "loading-spinner-small"
    this.buttonTarget.appendChild(spinner)
  }

  hideLoadingSpinner() {
    const spinner = document.querySelector(".loading-spinner-small")

    if (spinner) {
      spinner.remove()
    }
  }

  showError(_error) {
    const errorMessage = document.createElement("span")
    errorMessage.innerText =
      "Unable to complete download, please contact support"
    errorMessage.className = "govuk-error-message"
    this.buttonTarget.prepend(errorMessage)
  }

  clearError() {
    const errorMessage = document.querySelector(".govuk-error-message")

    if (errorMessage) {
      errorMessage.remove()
    }
  }
}
