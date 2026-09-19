import { LightningElement, api } from "lwc";

const MARK = {
  healthy: "#2e844a",
  warning: "#fe9339",
  critical: "#ea001e",
  info: "#0176d3"
};

/**
 * Section 11 - Critical Alerts Center. `alerts` is the live list built by
 * AccAlertsService from the other sections' own computed findings - already
 * sorted critical first, then warning, then most-recent-first within each
 * band.
 */
export default class AccCriticalAlerts extends LightningElement {
  @api alerts;

  get rows() {
    return (this.alerts || []).map((alert) => ({
      ...alert,
      icon: alert.severity === "critical" ? "utility:error" : "utility:warning",
      iconStyle: `--sds-c-icon-color-foreground-default:${MARK[alert.severity] || MARK.info};--sds-c-icon-color-foreground:${MARK[alert.severity] || MARK.info};`
    }));
  }

  get hasAlerts() {
    return this.rows.length > 0;
  }

  handleViewAll(event) {
    event.preventDefault();
  }
}
