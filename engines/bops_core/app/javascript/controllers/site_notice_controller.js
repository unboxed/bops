import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"
import QRCode from "qrcode"
import OpenSans_Bold from "../fonts/OpenSans-Bold"
import OpenSans_Regular from "../fonts/OpenSans-Regular"

const createPDF = () => {
  const pdf = new jsPDF({
    orientation: "portrait",
    unit: "pt",
    format: "a4",
    compress: true,
  })

  pdf.advancedAPI()

  pdf.addFileToVFS("OpenSans-Regular.ttf", OpenSans_Regular)
  pdf.addFont("OpenSans-Regular.ttf", "OpenSans", "normal", 400)

  pdf.addFileToVFS("OpenSans-Bold.ttf", OpenSans_Bold)
  pdf.addFont("OpenSans-Bold.ttf", "OpenSans", "normal", 700)

  pdf.setDisplayMode("fullpage", "single", "UseThumbs")

  return pdf
}

const setFont = (pdf, colour, size, weight) => {
  pdf.setTextColor(colour)
  pdf.setFontSize(size)
  pdf.setFont("OpenSans", "normal", weight)
}

const drawRect = (pdf, colour, x, y, width, height) => {
  pdf.setFillColor(colour)
  pdf.rect(x, y, width, height)
  pdf.fill()
}

const drawTriangle = (pdf, colour, x1, y1, x2, y2, x3, y3) => {
  pdf.setFillColor(colour)
  pdf.triangle(x1, y1, x2, y2, x3, y3)
  pdf.fill()
}

const drawLine = (pdf, colour, width, points) => {
  const start = points.shift()

  pdf.setDrawColor(colour)
  pdf.setLineWidth(width)
  pdf.moveTo(start[0], start[1])

  for (const point of points) {
    pdf.lineTo(point[0], point[1])
  }

  pdf.stroke()
}

const withGraphicsState = (pdf, block) => {
  pdf.saveGraphicsState()
  block.apply(null)
  pdf.restoreGraphicsState()
}

const drawHeader = (pdf, context, x, y, logo) => {
  const consultationEndDate = context.date

  const textOptions = {
    baseline: "hanging",
    lineHeightFactor: 1.4,
  }

  if (logo) {
    const logoCanvas = document.createElement("canvas")
    logoCanvas.width = logo.width
    logoCanvas.height = logo.height

    const logoContext = logoCanvas.getContext("2d")
    logoContext.drawImage(logo, 0, 0)

    pdf.addImage(logoCanvas, "PNG", x, y, logo.width / 4, logo.height / 4)
  } else {
    setFont(pdf, "#000000", 21, 700)
    pdf.text(context.localAuthority, x, y + 18, {
      align: "left",
      ...textOptions,
    })
  }

  setFont(pdf, "#000000", 21, 400)
  pdf.text("Planning application submitted", x + 515, y + 18, {
    align: "right",
    ...textOptions,
  })

  drawRect(pdf, "#000000", x, y + 45, 515, 70)

  setFont(pdf, "#FFFFFF", 18, 700)
  pdf.text("Tell us what you think before", x + 257.5, y + 70, {
    align: "center",
    ...textOptions,
  })
  pdf.text(consultationEndDate, x + 257.5, y + 95, {
    align: "center",
    ...textOptions,
  })
}

const drawProposal = (pdf, context, x, y) => {
  const proposal = context.proposal
  const reference = context.reference

  const textOptions = {
    align: "left",
    baseline: "hanging",
    lineHeightFactor: 1.4,
  }

  setFont(pdf, "#000000", 18, 700)
  pdf.text("Proposal", x, y, textOptions)

  setFont(pdf, "#000000", 16, 400)
  pdf.text(`(Ref: ${reference})`, x + 90, y, textOptions)

  const lines = pdf.splitTextToSize(proposal, 515)

  setFont(pdf, "#000000", 14, 400)
  pdf.text(lines.slice(0, 5), x, y + 30, textOptions)
}

const drawLocation = (pdf, context, x, y) => {
  const location = context.location

  const textOptions = {
    align: "left",
    baseline: "hanging",
    lineHeightFactor: 1.4,
  }

  setFont(pdf, "#000000", 18, 700)
  pdf.text("Location", x, y - 25, textOptions)

  setFont(pdf, "#000000", 14, 400)
  pdf.text(location, x, y, textOptions)
}

const drawMap = (pdf, x, y, map) => {
  const mapDOM = map.shadowRoot
  const mapCanvasses = mapDOM.querySelectorAll("canvas")

  for (const mapCanvas of mapCanvasses) {
    pdf.addImage(mapCanvas, "PNG", x, y, 273, 200)
  }

  pdf.setFillColor("#000000")
  pdf.setDrawColor("#000000")
  pdf.setLineWidth(1)

  pdf.rect(x, y, 273, 200)
  pdf.stroke()
}

const drawQRCode = (pdf, context, x, y) => {
  const url = `${context.url}?utm_source=qr_code`
  const qrCodeCanvas = document.createElement("canvas")

  const instructions = [
    "Scan this with your phone",
    "camera to get more information",
    "about the application, and",
    "submit your comments online",
  ]

  const textOptions = {
    align: "left",
    baseline: "hanging",
    lineHeightFactor: 1.4,
  }

  qrCodeCanvas.width = 800
  qrCodeCanvas.height = 800

  QRCode.toCanvas(qrCodeCanvas, url, (error, canvas) => {
    if (error) throw error
    pdf.addImage(canvas, "PNG", x, y, 200, 200)
  })

  setFont(pdf, "#000000", 12, 400)
  pdf.text(instructions, x, y - 80, textOptions)

  drawTriangle(pdf, "#000000", x + 80, y - 10, x + 100, y + 10, x + 120, y - 10)

  drawLine(pdf, "#000000", 3, [
    [x + 50, y],
    [x, y],
    [x, y + 50],
  ])
  drawLine(pdf, "#000000", 3, [
    [x + 150, y],
    [x + 200, y],
    [x + 200, y + 50],
  ])
  drawLine(pdf, "#000000", 3, [
    [x + 150, y + 200],
    [x + 200, y + 200],
    [x + 200, y + 150],
  ])
  drawLine(pdf, "#000000", 3, [
    [x + 50, y + 200],
    [x, y + 200],
    [x, y + 150],
  ])
}

const drawFooter = (pdf, context, x, y) => {
  const visibleUrl = context.url.replace(/^https?:\/\//, "")
  const heading = "Have your say at:"

  const textOptions = {
    align: "center",
    baseline: "hanging",
    lineHeightFactor: 1.4,
  }

  drawRect(pdf, "#000000", x, y, 515, 60)

  setFont(pdf, "#FFFFFF", 18, 700)
  pdf.text(heading, x + 257.5, y + 20, textOptions)

  setFont(pdf, "#FFFFFF", 12, 400)
  pdf.text(visibleUrl, x + 257.5, y + 42, textOptions)

  const urlWidth = pdf.getTextWidth(visibleUrl)
  const underlineLeft = Math.floor((595 - urlWidth) / 2)
  const underlineRight = Math.ceil(underlineLeft + urlWidth)

  const points = [
    [underlineLeft, y + 48],
    [underlineRight, y + 48],
  ]

  drawLine(pdf, "#FFFFFF", 1, points)

  pdf.link(x, 782 - y, 515, 60, { url: context.url })
}

const drawContactInformation = (pdf, context, x, y) => {
  const caseOfficer = context.caseOfficer
  const emailAddress = context.emailAddress
  const phoneNumber = context.phoneNumber

  const instructions = [
    "Please use the QR code or link to comment on the proposed development.",
    "If you contact us via phone, please name your case officer.",
  ]

  const textOptions = {
    align: "left",
    baseline: "hanging",
    lineHeightFactor: 1.4,
  }

  if (caseOfficer) {
    setFont(pdf, "#000000", 12, 400)
    pdf.text(
      "The case officer dealing with this application is:",
      x,
      y,
      textOptions,
    )

    setFont(pdf, "#000000", 12, 700)
    pdf.text(caseOfficer, x + 270, y, textOptions)

    y = y + 22
  }

  if (phoneNumber) {
    setFont(pdf, "#000000", 12, 700)
    pdf.text("Phone:", x, y, textOptions)

    setFont(pdf, "#000000", 12, 400)
    pdf.text(phoneNumber, x + 50, y, textOptions)
  }

  if (emailAddress) {
    const offset = phoneNumber ? 180 : 0

    setFont(pdf, "#000000", 12, 700)
    pdf.text("Email:", x + offset, y, textOptions)

    setFont(pdf, "#000000", 12, 400)
    pdf.text(emailAddress, x + offset + 50, y, textOptions)
  }

  if (phoneNumber || emailAddress) {
    y = y + 22
  }

  pdf.text(instructions, x, y + 8, textOptions)
}

export default class extends Controller {
  static targets = ["map", "logo"]
  static values = { context: Object }

  downloadPdf(event) {
    event.preventDefault()
    event.stopPropagation()

    const pdf = this.generateSiteNotice()
    pdf.save(`${this.reference}-site-notice.pdf`)
  }

  generateSiteNotice() {
    const pdf = createPDF()

    withGraphicsState(pdf, () => {
      drawHeader(
        pdf,
        this.contextValue,
        40,
        30,
        this.hasLogoTarget ? this.logoTarget : null,
      )
    })

    withGraphicsState(pdf, () => {
      drawProposal(pdf, this.contextValue, 40, 175)
    })

    withGraphicsState(pdf, () => {
      drawLocation(pdf, this.contextValue, 40, 345)
    })

    withGraphicsState(pdf, () => {
      drawMap(pdf, 40, 425, this.mapTarget)
    })

    withGraphicsState(pdf, () => {
      drawQRCode(pdf, this.contextValue, 355, 425)
    })

    withGraphicsState(pdf, () => {
      drawFooter(pdf, this.contextValue, 40, 650)
    })

    withGraphicsState(pdf, () => {
      drawContactInformation(pdf, this.contextValue, 40, 735)
    })

    return pdf
  }

  get reference() {
    return this.contextValue.reference
  }
}
