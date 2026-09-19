import { LightningElement, api } from "lwc";

/**
 * Section 7 - API & System Limits. `data` is the live AccModel.LimitSection
 * payload, sourced from System.OrgLimits. Every bar's width is current /
 * maximum x 100 - the same number printed beside it.
 */
export default class AccApiLimits extends LightningElement {
  @api data;

  get isUnavailable() {
    return !this.data || this.data.unavailable;
  }

  get unavailableReason() {
    return this.data ? this.data.unavailableReason : "";
  }

  get meters() {
    if (!this.data) {
      return [];
    }
    return (this.data.meters || []).map((meter) => ({
      ...meter,
      tooltip:
        meter.tooltip || `${meter.usageLabel} of the ${meter.label} limit used.`
    }));
  }

  get panel() {
    if (!this.data) {
      return [];
    }
    return (this.data.panel || []).map((row) => ({
      ...row,
      valueClass: row.unavailable
        ? "lim__status-value acc-unavailable"
        : "lim__status-value"
    }));
  }
}
