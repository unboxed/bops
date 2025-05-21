import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"

export default class extends Controller {
  static values = {
    reference: String,
  }

  downloadPdf() {
    const pdf = new jsPDF("p", "px", "a4")
    const content = document.getElementById("site-notice-content")

    pdf.html(content, {
      callback: (doc) => {
        doc.save(`${this.referenceValue}-site-notice.pdf`)
      },
    })
  }
}
