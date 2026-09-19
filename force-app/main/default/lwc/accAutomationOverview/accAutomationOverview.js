import { LightningElement, api } from "lwc";

const WASH = {
  healthy: "#ebf7ee",
  warning: "#fef5e9",
  critical: "#fef1f1",
  info: "#eef4ff"
};
const MARK = {
  healthy: "#2e844a",
  warning: "#fe9339",
  critical: "#ea001e",
  info: "#0176d3"
};

/**
 * Section 5 - Automation Overview: inventory table plus the status panel.
 * `data` is the live AccModel.AutomationSection payload.
 */
export default class AccAutomationOverview extends LightningElement {
  @api data;

  get isUnavailable() {
    return !this.data || this.data.unavailable;
  }

  get unavailableReason() {
    return this.data ? this.data.unavailableReason : "";
  }

  get rows() {
    if (!this.data) {
      return [];
    }
    return (this.data.inventory || []).map((row) => ({
      ...row,
      errorClass: row.hasErrors
        ? "acc-table__num acc-t-critical auto__errors"
        : "acc-table__num"
    }));
  }

  get panel() {
    if (!this.data) {
      return [];
    }
    return (this.data.panel || []).map((item) => ({
      ...item,
      badgeStyle: `background:${WASH[item.status] || WASH.info};`,
      iconStyle: `--sds-c-icon-color-foreground-default:${MARK[item.status] || MARK.info};--sds-c-icon-color-foreground:${MARK[item.status] || MARK.info};`,
      labelClass: item.unavailable
        ? "auto__panel-label acc-unavailable"
        : `auto__panel-label acc-t-${item.status}`
    }));
  }
}
