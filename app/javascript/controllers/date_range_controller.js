import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startDate", "endDate"]

  connect() {
    this.syncMinEndDate()
  }

  startDateChanged() {
    this.syncMinEndDate()
    if (this.hasStartDateTarget && this.hasEndDateTarget) {
      const startDateVal = this.startDateTarget.value
      if (startDateVal) {
        if (!this.endDateTarget.value || this.endDateTarget.value < startDateVal) {
          this.endDateTarget.value = startDateVal
        }
      }
    }
  }

  syncMinEndDate() {
    if (this.hasStartDateTarget && this.hasEndDateTarget) {
      const startDateVal = this.startDateTarget.value
      if (startDateVal) {
        this.endDateTarget.min = startDateVal
      }
    }
  }
}
