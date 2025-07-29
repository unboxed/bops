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
    const documents = this.documentsElementTarget.querySelectorAll(
      "[data-document-title-value]",
    )
    const zip = new JSZip()
    const fileNameMap = new Map()

    try {
      documents.forEach((document) => {
        const imageDownload = document.dataset.documentUrlValue
        const file = fetch(imageDownload).then((r) => r.blob())

        const originalFileName = document.dataset.documentTitleValue
        let fileName = originalFileName
        const nameCounter = fileNameMap.get(fileName) || 0

        if (nameCounter > 0) {
          const splitFileName = fileName.slice(0, fileName.lastIndexOf("."))
          const fileExtension = fileName.slice(fileName.lastIndexOf("."))
          fileName = `${splitFileName} (${nameCounter})${fileExtension}`
        }
        fileNameMap.set(originalFileName, nameCounter + 1)
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
    errorMessage.classList.add("govuk-!-padding-left-5")
    this.buttonTarget.append(errorMessage)
  }

  clearError() {
    const errorMessage = document.querySelector(".govuk-error-message")

    if (errorMessage) {
      errorMessage.remove()
    }
  }
}
