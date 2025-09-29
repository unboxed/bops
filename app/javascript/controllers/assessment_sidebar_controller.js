import { Controller } from "@hotwired/stimulus"

const WIDTH_STORAGE_FALLBACK_KEY = "assessmentSidebarWidth"

export default class extends Controller {
  static targets = ["panel", "handle", "summaryBody", "summaryToggle"]

  static values = {
    defaultWidth: { type: Number, default: 320 },
    minWidth: { type: Number, default: 240 },
    maxWidth: { type: Number, default: 520 },
    storageKey: { type: String, default: WIDTH_STORAGE_FALLBACK_KEY },
  }

  connect() {
    this.boundResize = this.resize.bind(this)
    this.boundStopResize = this.stopResize.bind(this)

    this.applyStoredWidth()
    this.markCurrentTask()
    this.element.classList.add("app-assessment-sidebar--enhanced")
    this.showSummary()
  }

  disconnect() {
    this.removeResizeListeners()
  }

  toggleSummary(event) {
    event.preventDefault()
    if (!this.hasSummaryBodyTarget || !this.hasSummaryToggleTarget) return

    const expanded =
      this.summaryToggleTarget.getAttribute("aria-expanded") === "true"
    if (expanded) {
      this.summaryToggleTarget.setAttribute("aria-expanded", "false")
      this.summaryBodyTarget.hidden = true
      this.summaryToggleTarget.classList.add(
        "app-assessment-sidebar__summary-toggle--collapsed",
      )
    } else {
      this.showSummary()
    }
  }

  showSummary() {
    if (!this.hasSummaryBodyTarget || !this.hasSummaryToggleTarget) return

    this.summaryToggleTarget.setAttribute("aria-expanded", "true")
    this.summaryBodyTarget.hidden = false
    this.summaryToggleTarget.classList.remove(
      "app-assessment-sidebar__summary-toggle--collapsed",
    )
  }

  startResize(event) {
    if (event.button && event.button !== 0) return

    event.preventDefault()

    this.startX = event.clientX
    this.startingWidth = this.currentWidth || this.element.offsetWidth

    document.addEventListener("pointermove", this.boundResize)
    document.addEventListener("pointerup", this.boundStopResize, { once: true })

    if (this.hasHandleTarget && this.handleTarget.setPointerCapture) {
      this.handleTarget.setPointerCapture(event.pointerId)
    }

    this.element.classList.add("app-assessment-sidebar--resizing")
  }

  resize(event) {
    const delta = event.clientX - this.startX
    const proposedWidth = this.startingWidth + delta

    this.applyWidth(proposedWidth)
  }

  stopResize(event) {
    if (this.hasHandleTarget && this.handleTarget.releasePointerCapture) {
      try {
        this.handleTarget.releasePointerCapture(event.pointerId)
      } catch (_error) {
        // ignore release errors when pointer capture was not set
      }
    }

    this.removeResizeListeners()
    this.persistWidth()
    this.element.classList.remove("app-assessment-sidebar--resizing")
  }

  handleKeydown(event) {
    const step = event.shiftKey ? 40 : 16
    let handled = true
    let width = this.currentWidth || this.element.offsetWidth

    switch (event.key) {
      case "ArrowLeft":
        width -= step
        break
      case "ArrowRight":
        width += step
        break
      case "Home":
        width = this.minWidthValue
        break
      case "End":
        width = this.maxWidthValue
        break
      default:
        handled = false
    }

    if (!handled) return

    event.preventDefault()
    this.applyWidth(width)
    this.persistWidth()
  }

  applyStoredWidth() {
    const storedWidth = this.readStoredWidth()
    const width = storedWidth || this.defaultWidthValue

    this.applyWidth(width)
  }

  applyWidth(width) {
    const clampedWidth = this.clampWidth(width)

    this.currentWidth = clampedWidth
    this.element.style.setProperty(
      "--app-assessment-sidebar-width",
      `${clampedWidth}px`,
    )
    this.element.style.width = `${clampedWidth}px`

    if (this.hasPanelTarget) {
      this.panelTarget.style.width = `${clampedWidth}px`
    }

    if (this.hasHandleTarget) {
      this.handleTarget.setAttribute(
        "aria-valuenow",
        Math.round(clampedWidth).toString(),
      )
    }
  }

  clampWidth(width) {
    return Math.min(this.maxWidthValue, Math.max(this.minWidthValue, width))
  }

  markCurrentTask() {
    if (!this.hasPanelTarget) return

    const links = this.panelTarget.querySelectorAll("a[href]")
    if (!links.length) return

    const currentPath = window.location.pathname
    let activeLink = null

    links.forEach((link) => {
      try {
        const url = new URL(link.href, window.location.origin)

        if (url.pathname === currentPath) {
          activeLink = link
        }
      } catch (_error) {
        // Ignore malformed URLs
      }
    })

    if (!activeLink) {
      activeLink = Array.from(links).find((link) => {
        try {
          const url = new URL(link.href, window.location.origin)
          return currentPath.startsWith(url.pathname) && url.pathname !== "/"
        } catch (_error) {
          return false
        }
      })
    }

    if (!activeLink) return

    activeLink.setAttribute("aria-current", "page")
    const parentItem = activeLink.closest(".app-assessment-sidebar__task")

    if (parentItem) {
      parentItem.classList.add("app-assessment-sidebar__task--active")
    }
  }

  removeResizeListeners() {
    document.removeEventListener("pointermove", this.boundResize)
    document.removeEventListener("pointerup", this.boundStopResize)
  }

  readStoredWidth() {
    if (!this.storageAvailable) return null

    let storedValue

    try {
      storedValue = window.localStorage.getItem(this.storageKey)
    } catch (_error) {
      return null
    }
    const parsed = parseInt(storedValue, 10)

    return Number.isFinite(parsed) ? parsed : null
  }

  persistWidth() {
    if (!this.storageAvailable || !this.currentWidth) return

    try {
      window.localStorage.setItem(
        this.storageKey,
        Math.round(this.currentWidth),
      )
    } catch (_error) {
      // Ignore storage failures
    }
  }

  get storageAvailable() {
    return typeof window !== "undefined" && "localStorage" in window
  }

  get storageKey() {
    return this.storageKeyValue || WIDTH_STORAGE_FALLBACK_KEY
  }
}
