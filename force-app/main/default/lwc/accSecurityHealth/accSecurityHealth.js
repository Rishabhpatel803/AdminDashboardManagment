import { LightningElement, api } from "lwc";

/**
 * Section 4 - Security & Access Health. `data` is the live
 * AccModel.SecuritySection payload. The Access Health donut is the Security
 * Health Score from the server's deduction ledger, and every deduction has a
 * matching row in Security Alerts so the score is explainable from the page.
 */
export default class AccSecurityHealth extends LightningElement {
  @api data;

  get inventory() {
    if (!this.data) {
      return [];
    }
    return (this.data.inventory || []).map((tile) => ({
      ...tile,
      valueClass: tile.unavailable
        ? "metric__value acc-unavailable"
        : "metric__value"
    }));
  }

  get alerts() {
    if (!this.data) {
      return [];
    }
    return (this.data.alerts || []).map((alert) => ({
      ...alert,
      countClass: alert.unavailable
        ? "sec__alert-count acc-tabular acc-unavailable"
        : "sec__alert-count acc-tabular"
    }));
  }

  get donut() {
    return this.data ? this.data.donut : null;
  }

  get subsystems() {
    return this.data ? this.data.subsystems || [] : [];
  }
}
