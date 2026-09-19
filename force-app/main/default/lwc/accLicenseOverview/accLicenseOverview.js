import { LightningElement, api } from "lwc";

const MARK = {
  healthy: "#2e844a",
  warning: "#fe9339",
  critical: "#ea001e",
  info: "#0176d3"
};

/**
 * Section 3 - License Overview. `data` is the live AccModel.LicenseSection
 * payload. The donut shows primary Salesforce license utilisation; the
 * supporting categories each carry their own independently-calculated status.
 */
export default class AccLicenseOverview extends LightningElement {
  @api data;

  get isUnavailable() {
    return !this.data || this.data.unavailable;
  }

  get unavailableReason() {
    return this.data ? this.data.unavailableReason : "";
  }

  get donut() {
    return this.data ? this.data.donut : null;
  }

  get primaryName() {
    return this.data ? this.data.primaryName : "";
  }

  get primaryCountLabel() {
    return this.data ? this.data.primaryCountLabel : "";
  }

  get primaryAvailableLabel() {
    return this.data ? this.data.primaryAvailableLabel : "";
  }

  get supporting() {
    if (!this.data) {
      return [];
    }
    return (this.data.supporting || []).map((row) => ({
      ...row,
      barStyle: `background:${MARK[row.status] || MARK.info};`
    }));
  }
}
