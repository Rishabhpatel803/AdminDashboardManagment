import { LightningElement, api } from "lwc";

/**
 * Section 9 - Apex & Code Health. `data` is the live AccModel.CodeSection
 * payload. Apex inventory (classes, triggers, jobs) is real; org-wide test
 * coverage requires the Tooling API, which Apex SOQL cannot reach, so the
 * donut reports Data Unavailable.
 */
export default class AccCodeHealth extends LightningElement {
  @api data;

  get donut() {
    return this.data ? this.data.donut : null;
  }

  get rows() {
    if (!this.data) {
      return [];
    }
    return (this.data.rows || []).map((row) => ({
      ...row,
      valueClass: row.unavailable
        ? "code__row-value acc-unavailable"
        : "code__row-value"
    }));
  }

  get status() {
    return this.data ? this.data.status : "info";
  }

  get coverageUnavailable() {
    return this.data ? this.data.coverageUnavailable : true;
  }

  get coverageUnavailableReason() {
    return this.data ? this.data.coverageUnavailableReason : "";
  }
}
