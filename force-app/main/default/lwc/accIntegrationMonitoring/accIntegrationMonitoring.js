import { LightningElement, api } from "lwc";

const MARK = {
  healthy: "#2e844a",
  warning: "#fe9339",
  critical: "#ea001e",
  info: "#0176d3"
};

/**
 * Section 6 - Integration Monitoring. `data` is the live
 * AccModel.IntegrationSection payload. The org can confirm which integrations
 * are CONFIGURED (named credentials); it cannot confirm they are UP without
 * an outbound callout, so the health donut reports Data Unavailable.
 */
export default class AccIntegrationMonitoring extends LightningElement {
  @api data;

  get systems() {
    if (!this.data) {
      return [];
    }
    return (this.data.systems || []).map((system) => ({
      ...system,
      iconStyle: `--sds-c-icon-color-foreground-default:${MARK[system.status] || MARK.info};--sds-c-icon-color-foreground:${MARK[system.status] || MARK.info};`
    }));
  }

  get systemsUnavailable() {
    return this.data ? this.data.systemsUnavailable : false;
  }

  get systemsUnavailableReason() {
    return this.data ? this.data.systemsUnavailableReason : "";
  }

  get details() {
    if (!this.data) {
      return [];
    }
    return (this.data.details || []).map((row) => ({
      ...row,
      valueClass: row.unavailable
        ? "int__detail-value acc-unavailable"
        : "int__detail-value"
    }));
  }

  get donut() {
    return this.data ? this.data.donut : null;
  }
}
