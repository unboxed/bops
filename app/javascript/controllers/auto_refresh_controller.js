import { Controller } from "@hotwired/stimulus"

const STORAGE_PREFIX = "auto-refresh"

export default class extends Controller {
  static values = {
    interval: { type: Number, default: 5000 },
    storageKey: String,
  }

  connect() {
    this.storageKey =
      this.storageKeyValue ||
      `${STORAGE_PREFIX}:${window.location.pathname}${window.location.search}`

    this.storeState = this.storeState.bind(this)
    this.handleVisibilityChange = this.handleVisibilityChange.bind(this)

    this.restoreScrollPosition()
    this.startAutoRefresh()

    window.addEventListener("beforeunload", this.storeState)
    document.addEventListener("visibilitychange", this.handleVisibilityChange)
  }

  disconnect() {
    this.stopAutoRefresh()
    window.removeEventListener("beforeunload", this.storeState)
    document.removeEventListener(
      "visibilitychange",
      this.handleVisibilityChange,
    )
  }

  startAutoRefresh() {
    this.stopAutoRefresh()

    this.refreshTimer = window.setInterval(() => {
      this.storeState()
      window.location.reload()
    }, this.intervalValue)
  }

  stopAutoRefresh() {
    if (this.refreshTimer) {
      window.clearInterval(this.refreshTimer)
      this.refreshTimer = null
    }
  }

  storeState() {
    try {
      const state = {
        scrollY: window.scrollY,
        viewportHeight: window.innerHeight,
        timestamp: Date.now(),
      }
      window.sessionStorage.setItem(this.storageKey, JSON.stringify(state))
    } catch (_error) {
      // Swallow storage errors (e.g. quota exceeded or disabled storage)
    }
  }

  restoreScrollPosition() {
    let storedState
    try {
      storedState = window.sessionStorage.getItem(this.storageKey)
    } catch (_error) {
      storedState = null
    }

    if (!storedState) return

    try {
      const { scrollY, viewportHeight } = JSON.parse(storedState)
      if (!Number.isFinite(scrollY)) return

      const docElement = document.scrollingElement || document.documentElement
      const availableHeight = docElement.scrollHeight
      const viewport = Number.isFinite(viewportHeight)
        ? viewportHeight
        : window.innerHeight
      const maxScroll = Math.max(0, availableHeight - viewport)
      const targetScroll = Math.min(scrollY, maxScroll)

      window.requestAnimationFrame(() => {
        window.scrollTo(0, targetScroll)
        try {
          window.sessionStorage.removeItem(this.storageKey)
        } catch (_error) {
          // Ignore storage errors on cleanup
        }
      })
    } catch (_error) {
      // Ignore malformed storage contents
    }
  }

  handleVisibilityChange() {
    if (document.visibilityState === "hidden") {
      this.storeState()
    }
  }
}
