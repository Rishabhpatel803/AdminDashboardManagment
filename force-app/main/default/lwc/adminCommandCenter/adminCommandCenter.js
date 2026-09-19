import { LightningElement } from "lwc";
import getDashboard from "@salesforce/apex/AccAdminCommandCenterController.getDashboard";

/**
 * adminCommandCenter - the Salesforce Admin Command Center home page.
 *
 * Makes exactly one Apex round trip (AccAdminCommandCenterController.getDashboard)
 * and distributes the resulting payload to all 13 section components as
 * plain @api data. Every number on the page is computed server-side, once,
 * against the same snapshot of live org data - there is no client-side mock
 * model.
 */
export default class AdminCommandCenter extends LightningElement {
  payload;
  error;
  isLoading = true;

  connectedCallback() {
    this.load();
  }

  load() {
    this.isLoading = true;
    this.error = undefined;
    getDashboard()
      .then((result) => {
        this.payload = result;
      })
      .catch((error) => {
        this.error = error;
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  handleRetry() {
    this.load();
  }

  get hasError() {
    return Boolean(this.error) && !this.isLoading;
  }

  get hasData() {
    return Boolean(this.payload) && !this.error && !this.isLoading;
  }

  get errorMessage() {
    if (!this.error) {
      return "";
    }
    if (this.error.body && this.error.body.message) {
      return this.error.body.message;
    }
    return this.error.message || "Unable to load the Admin Command Center.";
  }

  /** Announced to assistive tech so the page state is not visual-only. */
  get summary() {
    if (!this.payload) {
      return "";
    }
    const health = this.payload.health;
    const criticalCount = (this.payload.alerts || []).filter(
      (alert) => alert.severity === "critical"
    ).length;
    return `Salesforce instance ${this.payload.org.instanceId}, system health ${health.statusLabel}, ${criticalCount} critical alerts. ${this.payload.meta.lastUpdatedLabel}.`;
  }
}
