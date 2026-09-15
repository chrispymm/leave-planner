import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  clickOutside(event) {
    if (event.target === this.element) {
      this.close()
    }
  }

  close() {
    const frame = this.element.closest("turbo-frame")
    if (frame) {
      frame.innerHTML = ""
    } else {
      this.element.remove()
    }
  }
}
