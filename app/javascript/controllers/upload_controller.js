import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  toggle(event) {
    event.preventDefault()
    if (this.hasFormTarget) this.formTarget.classList.toggle("hidden")
  }
}
