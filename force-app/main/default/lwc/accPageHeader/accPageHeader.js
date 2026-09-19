import { LightningElement, api } from "lwc";

/**
 * accPageHeader - hero header. Receives the live org, health and meta
 * payloads from the root component's single Apex call, so the header can
 * never disagree with the sections below it.
 */
export default class AccPageHeader extends LightningElement {
  @api org;
  @api health;
  @api meta;

  get subtitle() {
    const environment = this.org ? this.org.environment : "";
    return `Complete Instance Overview • ${environment}`;
  }

  get infoBlocks() {
    if (!this.org || !this.health) {
      return [];
    }
    return [
      {
        id: "instance",
        label: "Instance",
        value: this.org.instanceId
      },
      {
        id: "environment",
        label: "Environment",
        value: this.org.environment,
        status: "healthy"
      },
      {
        id: "release",
        label: "Release",
        value: this.org.release
      },
      {
        id: "health",
        label: "System Health",
        value: this.health.statusLabel,
        status: this.health.status,
        tooltip: this.health.tooltip
      }
    ];
  }

  /** Spec: show a warning stamp when the data is past its refresh window. */
  get isStale() {
    return this.meta && this.meta.stale;
  }

  get lastUpdatedLabel() {
    return this.meta ? this.meta.lastUpdatedLabel : "";
  }
}
