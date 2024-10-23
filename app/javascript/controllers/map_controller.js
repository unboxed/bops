import { Controller } from "@hotwired/stimulus"
import "leaflet"
import "leaflet-css"

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
    })

    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 25,
      attribution:
        '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(this.map)

    if (neighbours !== null) {
      for (const summary_tag in neighbours) {
        layers.push(
          this.buildNeighboursLayer(neighbours[summary_tag], summary_tag),
        )
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

  handleEvent(ev) {
    const constraintLayer = this.constraintsLayers[ev.params.constraint]

    if (ev.target.checked) {
      this.map.addLayer(constraintLayer)
    } else {
      this.map.removeLayer(constraintLayer)
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

    const heading = this.element.querySelector("h3")
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
