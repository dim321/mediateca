import { Controller } from "@hotwired/stimulus"

// Manages date picker for schedule view and inline price editing
export default class extends Controller {
  static targets = ["dateInput"]

  connect() {
    // Initialize with current date if no value set
  }

  navigate(event) {
    event.preventDefault()
    const date = this.dateInputTarget.value
    if (date) {
      const url = new URL(window.location)
      url.searchParams.set("date", date)
      window.Turbo.visit(url.toString())
    }
  }
}
