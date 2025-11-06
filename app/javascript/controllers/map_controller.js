import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

L.Map.mergeOptions({
  gestureHandlingOptions: {
    text: {
      touch: "Use two fingers to move the map",
      scroll: "Use ctrl + scroll to zoom the map",
      scrollMac: "Use \u2318 + scroll to zoom the map",
    },
    duration: 1500,
  },
})

const _nativeEvents = [
  "touchstart",
  "touchmove",
  "touchend",
  "touchcancel",
  "click",
]

let draggingMap = false

const GestureHandling = L.Handler.extend({
  addHooks: function () {
    const map = this._map
    const container = map._container

    this._handleTouch = this._handleTouch.bind(this)

    this._setLanguageContent()
    this._disableInteractions()

    L.DomUtil.addClass(container, "leaflet-gesture-handling")

    // Uses native event listeners instead of L.DomEvent due to issues with Android touch events turning into pointer events.
    for (const _nativeEvent of _nativeEvents) {
      container.addEventListener(_nativeEvents, this._handleTouch)
    }

    L.DomEvent.on(container, "wheel", this._handleScroll, this)
    L.DomEvent.on(map, "mouseover", this._handleMouseOver, this)
    L.DomEvent.on(map, "mouseout", this._handleMouseOut, this)

    // Listen to these events so will not disable dragging if the user moves the mouse out the boundary of the map container whilst actively dragging the map.
    L.DomEvent.on(map, "movestart", this._handleDragging, this)
    L.DomEvent.on(map, "move", this._handleDragging, this)
    L.DomEvent.on(map, "moveend", this._handleDragging, this)
  },

  removeHooks: function () {
    const map = this._map
    const container = map._container

    this._enableInteractions()

    L.DomUtil.removeClass(container, "leaflet-gesture-handling")

    for (const _nativeEvent of _nativeEvents) {
      container.removeEventListener(_nativeEvent, this._handleTouch)
    }

    L.DomEvent.off(container, "wheel", this._handleScroll, this)
    L.DomEvent.off(this._map, "mouseover", this._handleMouseOver, this)
    L.DomEvent.off(this._map, "mouseout", this._handleMouseOut, this)

    L.DomEvent.off(this._map, "movestart", this._handleDragging, this)
    L.DomEvent.off(this._map, "move", this._handleDragging, this)
    L.DomEvent.off(this._map, "moveend", this._handleDragging, this)
  },

  _handleDragging: (e) => {
    if (e.type === "movestart" || e.type === "move") {
      draggingMap = true
    } else if (e.type === "moveend") {
      draggingMap = false
    }
  },

  _disableInteractions: function () {
    const map = this._map

    map.dragging.disable()
    map.scrollWheelZoom.disable()

    if (map.tap) {
      map.tap.disable()
    }
  },

  _enableInteractions: function () {
    const map = this._map

    map.dragging.enable()
    map.scrollWheelZoom.enable()

    if (map.tap) {
      map.tap.enable()
    }
  },

  _setLanguageContent: function () {
    const map = this._map
    const container = map._container
    const languageContent = this._map.options.gestureHandlingOptions.text

    let mac = false

    if (navigator.platform.toUpperCase().indexOf("MAC") >= 0) {
      mac = true
    }

    let scrollContent = languageContent.scroll

    if (mac) {
      scrollContent = languageContent.scrollMac
    }

    container.setAttribute(
      "data-gesture-handling-touch-content",
      languageContent.touch,
    )

    container.setAttribute(
      "data-gesture-handling-scroll-content",
      scrollContent,
    )
  },

  _handleTouch: function (e) {
    const map = this._map
    const container = map._container

    // Disregard touch events on the minimap if present
    const ignoreList = [
      "leaflet-control-minimap",
      "leaflet-interactive",
      "leaflet-popup-content",
      "leaflet-popup-content-wrapper",
      "leaflet-popup-close-button",
      "leaflet-control-zoom-in",
      "leaflet-control-zoom-out",
    ]

    let ignoreElement = false

    for (let i = 0; i < ignoreList.length; i++) {
      if (L.DomUtil.hasClass(e.target, ignoreList[i])) {
        ignoreElement = true
      }
    }

    if (ignoreElement) {
      if (
        L.DomUtil.hasClass(e.target, "leaflet-interactive") &&
        e.type === "touchmove" &&
        e.touches.length === 1
      ) {
        L.DomUtil.addClass(container, "leaflet-gesture-handling--touch-warning")

        this._disableInteractions()
      } else {
        L.DomUtil.removeClass(
          container,
          "leaflet-gesture-handling--touch-warning",
        )
      }

      return
    }

    // screenLog(e.type+' '+e.touches.length)
    if (e.type !== "touchmove" && e.type !== "touchstart") {
      L.DomUtil.removeClass(
        container,
        "leaflet-gesture-handling--touch-warning",
      )

      return
    }

    if (e.touches.length === 1) {
      L.DomUtil.addClass(container, "leaflet-gesture-handling--touch-warning")

      this._disableInteractions()
    } else {
      e.preventDefault()
      this._enableInteractions()

      L.DomUtil.removeClass(
        container,
        "leaflet-gesture-handling--touch-warning",
      )
    }
  },

  _isScrolling: false,

  _handleScroll: function (e) {
    const map = this._map
    const container = map._container

    if (e.metaKey || e.ctrlKey) {
      e.preventDefault()
      L.DomUtil.removeClass(
        container,
        "leaflet-gesture-handling--scroll-warning",
      )

      map.scrollWheelZoom.enable()
    } else {
      L.DomUtil.addClass(container, "leaflet-gesture-handling--scroll-warning")
      map.scrollWheelZoom.disable()

      clearTimeout(this._isScrolling)

      // Set a timeout to run after scrolling ends
      this._isScrolling = setTimeout(() => {
        // Run the callback
        const warnings = document.getElementsByClassName(
          "leaflet-gesture-handling--scroll-warning",
        )

        for (let i = 0; i < warnings.length; i++) {
          L.DomUtil.removeClass(
            warnings[i],
            "leaflet-gesture-handling--scroll-warning",
          )
        }
      }, map.options.gestureHandlingOptions.duration)
    }
  },

  _handleMouseOver: function () {
    this._enableInteractions()
  },

  _handleMouseOut: function () {
    if (!draggingMap) {
      this._disableInteractions()
    }
  },
})

L.Map.addInitHook("addHandler", "gestureHandling", GestureHandling)

export default class extends Controller {
  connect() {
    L.Icon.Default.imagePath = "/assets"

    this.mapElement = this.element.querySelector("#map")

    const layerData = JSON.parse(this.element.dataset.layers)
    const redline = layerData.redline
    const neighbours = layerData.neighbours
    const constraints = layerData.constraints

    const layers = []
    this.constraintsLayers = {}
    this.neighboursLayers = {}

    let [lat, long, ..._] = this.element.dataset.latlong.split(",")

    if (redline !== null) {
      const geoJsonLayer = L.geoJson(redline, {
        style: {
          color: "#ff0000",
          weight: 2,
          opacity: 0.67,
        },
      })
      layers.push(geoJsonLayer)
      const centre = geoJsonLayer.getBounds().getCenter()
      lat = centre.lat
      long = centre.lng
    }

    this.map = L.map(this.mapElement.id, {
      center: [lat, long],
      zoom: 17,
      gestureHandling: true,
    })

    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 25,
      attribution:
        '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(this.map)

    if (neighbours !== null) {
      for (const summary_tag in neighbours) {
        const layer = this.buildNeighboursLayer(
          neighbours[summary_tag],
          summary_tag,
        )
        layers.push(layer)
        this.neighboursLayers[`${summary_tag}`] = layer
      }
    }

    if (constraints !== null) {
      let i = 0
      for (const constraintEntity in constraints) {
        const layer = this.buildConstraintsLayer(
          constraintEntity,
          constraints[constraintEntity],
        )
        layers.push(layer)
        this.constraintsLayers[`${constraintEntity}_${i++}`] = layer
      }
    }

    for (const layer of layers) {
      layer.addTo(this.map)
    }
  }

  buildNeighboursLayer(neighboursList, summary_tag) {
    const colours = {
      supportive: { fill: "#cce2d8", border: "#005a30" },
      neutral: { fill: "#fff7bf", border: "#594d00" },
      objection: { fill: "#f6d7d2", border: "#942514" },
      no_response: { fill: "#d2e2f1", border: "#003078" },
    }

    const neighbourMarkerOptions = {
      radius: 8,
      fillColor: colours[summary_tag].fill,
      color: colours[summary_tag].border,
      weight: 1,
      opacity: 1,
      fillOpacity: 1,
    }

    const neighboursCollection = {
      type: "FeatureCollection",
      features: neighboursList.map((point) => {
        return {
          type: "Feature",
          geometry: point,
        }
      }),
    }

    return L.geoJson(neighboursCollection, {
      pointToLayer: (_feature, latlng) => {
        const marker = L.circleMarker(latlng, neighbourMarkerOptions)
        marker.on("click", (_ev) => {
          this.filterNeighbourList(latlng)
        })

        return marker
      },
    })
  }

  buildConstraintsLayer(constraintEntity, geoJsonData) {
    const colours = {
      "agricultural-land-classification": {
        fill: "#00703c33",
        border: "#00703c",
      },
      "ancient-woodland": { fill: "#00703c33", border: "#00703c" },
      "area-of-outstanding-natural-beauty": {
        fill: "#d5388099",
        border: "#d53880",
      },
      "article-4-direction-area": { fill: "#00307899", border: "#003078" },
      battlefield: { fill: "#4d294233", border: "#4d2942" },
      border: { fill: "#0b0c0c19", border: "#0b0c0c" },
      "brownfield-site": { fill: "#74572999", border: "#745729" },
      "building-preservation-notice": { fill: "#f944c799", border: "#f944c7" },
      "built-up-area": { fill: "#f4773899", border: "#f47738" },
      "central-activities-zone": { fill: "#00307899", border: "#003078" },
      "certificate-of-immunity": { fill: "#D8760D99", border: "#D8760D" },
      "conservation-area": { fill: "#78AA0099", border: "#78AA00" },
      "design-code-area": { fill: "#00307899", border: "#003078" },
      "educational-establishment": { fill: "#00307899", border: "#003078" },
      "flood-risk-zone": { fill: "#00307899", border: "#003078" },
      "flood-storage-area": { fill: "#00307899", border: "#003078" },
      "green-belt": { fill: "#85994b99", border: "#85994b" },
      "heritage-at-risk": { fill: "#8D73AF99", border: "#8D73AF" },
      "heritage-coast": { fill: "#912b8899", border: "#912b88" },
      "infrastructure-project": { fill: "#00307899", border: "#003078" },
      "listed-building-outline": { fill: "#F9C74499", border: "#F9C744" },
      "local-authority-district": { fill: "#0b0c0c19", border: "#0b0c0c" },
      "locally-listed-building": { fill: "#F9C74499", border: "#F9C744" },
      "local-nature-reserve": { fill: "#00307899", border: "#003078" },
      "local-planning-authority": { fill: "#00307899", border: "#003078" },
      "local-resilience-forum-boundary": {
        fill: "#f499be19",
        border: "#f499be",
      },
      "national-nature-reserve": { fill: "#00307899", border: "#003078" },
      "national-park": { fill: "#3DA52C99", border: "#3DA52C" },
      "nature-improvement-area": { fill: "#00307899", border: "#003078" },
      parish: { fill: "#5694ca99", border: "#5694ca" },
      "park-and-garden": { fill: "#0EB95199", border: "#0EB951" },
      "protected-wreck-site": { fill: "#0b0c0c99", border: "#0b0c0c" },
      ramsar: { fill: "#7fcdff99", border: "#7fcdff" },
      region: { fill: "#00307899", border: "#003078" },
      "scheduled-monument": { fill: "#0F9CDA99", border: "#0F9CDA" },
      "site-of-special-scientific-interest": {
        fill: "#308fac99",
        border: "#308fac",
      },
      "special-area-of-conservation": { fill: "#7A870599", border: "#7A8705" },
      "special-protection-area": { fill: "#00307899", border: "#003078" },
      "title-boundary": { fill: "#00307899", border: "#003078" },
      "transport-access-node": { fill: "#00307899", border: "#003078" },
      "tree-preservation-zone": { fill: "#00307899", border: "#003078" },
      ward: { fill: "#3DA52C99", border: "#3DA52C" },
      "world-heritage-site": { fill: "#EB1EE599", border: "#EB1EE5" },
      "world-heritage-site-buffer-zone": {
        fill: "#EB1EE533",
        border: "#EB1EE5",
      },
    }

    return L.geoJson(geoJsonData, {
      style: {
        fillColor: colours[constraintEntity]?.fill || "#00000033",
        color: colours[constraintEntity]?.border || "#000000",
        weight: 2,
        opacity: 1,
        fillOpacity: 0.5,
      },
    })
  }

  showMapData(ev) {
    ev.target.classList.add("govuk-!-display-none")
    ev.target.parentNode
      .querySelector(".map-data")
      .classList.remove("govuk-!-display-none")
  }

  hideMapData(ev) {
    ev.target.parentNode.classList.add("govuk-!-display-none")
    ev.target.parentNode.parentNode
      .querySelector(".map-data-toggle")
      .classList.remove("govuk-!-display-none")
    this.filterNeighbourList(null)
  }

  toggleTab(ev) {
    ev.preventDefault()
    this.filterNeighbourList(null)
    for (const el of this.element.querySelectorAll(".map-data-tab")) {
      if (el.classList.contains(`map-data-${ev.params.toggle}`)) {
        el.classList.remove("govuk-!-display-none")
      } else {
        el.classList.add("govuk-!-display-none")
      }
    }
  }

  handleConstraintEvent(ev) {
    const constraintLayer = this.constraintsLayers[ev.params.constraint]

    if (ev.target.checked) {
      this.map.addLayer(constraintLayer)
    } else {
      this.map.removeLayer(constraintLayer)
    }
  }

  handleNeighbourEvent(ev) {
    const neighbourLayer = this.neighboursLayers[ev.params.neighbour]

    if (ev.target.checked) {
      this.map.addLayer(neighbourLayer)
    } else {
      this.map.removeLayer(neighbourLayer)
    }
  }

  filterNeighbourList(latlng) {
    if (latlng !== null) {
      this.showMapData({ target: this.element.querySelector("button") })
      this.toggleTab({
        params: { toggle: "neighbours" },
        preventDefault: () => {},
      })
    }
    const lonlatStr =
      latlng === null ||
      `${this.trunc(latlng.lng, 5)},${this.trunc(latlng.lat, 5)}`

    const els = this.element.querySelectorAll("li")
    for (const el of els) {
      if (latlng === null || el.dataset.lonlat === lonlatStr) {
        el.classList.remove("govuk-!-display-none")
      } else {
        el.classList.add("govuk-!-display-none")
      }
    }

    const heading = this.element.querySelector("#neighbour-heading")
    heading.innerHTML = latlng === null ? "All neighbours" : "Neighbours"
  }

  trunc(num, digits) {
    const sign = Math.abs(num) === num ? "" : "-"
    const whole = Math.trunc(num)
    const remainder = num - whole
    const decimals = String(remainder)
      .split(".")[1]
      .slice(0, digits)
      .replace(/0+$/, "")
    return `${sign}${whole}.${decimals}`
  }
}
