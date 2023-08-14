import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radius"]

  fetchData(event) {
    event.preventDefault()

    this.handleRadiusSearch()
  }

  async handleRadiusSearch() {
    const latLng = document.querySelector("#lat_lng").value
    const radius = this.radiusTarget.value
    const url = `${document.querySelector("#os_radius_path").value}?point=${latLng}&radius=${radius}`

    try {
      let response = await fetch(url)

      if (!response.ok) {
        throw new Error(`There is a HTTP error with status: ${response.status}`)
      }

      let data = await response.json()
      const parsedData = data.body ? JSON.parse(data.body) : data

      if (!parsedData?.results?.length) {
        console.log(`No addresses found in a radius of ${radius}m`)
        return
      }

      const addresses = parsedData.results.map(result => result.DPA.ADDRESS)
      this.appendAddressesToPage(addresses)
    } catch (error) {
      console.error("There was an error calling the service:", error)
    }
  }

  appendAddressesToPage(addresses) {
    console.log(addresses)
    const container = document.getElementById("address-container")

    container.innerHTML = ""
    addresses.forEach((address) => {
      const p = document.createElement("p")
      p.classList.add("govuk-body")
      p.textContent = address
      container.appendChild(p)
    })
  }
}
