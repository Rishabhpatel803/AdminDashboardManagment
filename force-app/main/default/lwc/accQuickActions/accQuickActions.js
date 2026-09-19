import { LightningElement } from "lwc";

/**
 * Section 13 - Quick Admin Actions.
 *
 * Spec Sec 14: "Quick Actions do not require calculations." These are static
 * navigation targets into standard Salesforce Setup pages, not org data, so
 * they are declared here rather than fetched from Apex.
 */
const ACTIONS = [
  {
    id: "q1",
    label: "Create User",
    icon: "utility:adduser",
    target: "/lightning/setup/ManageUsers/home",
    accent: "#0176d3"
  },
  {
    id: "q2",
    label: "Manage Access",
    icon: "utility:lock",
    target: "/lightning/setup/PermSets/home",
    accent: "#9050e9"
  },
  {
    id: "q3",
    label: "View Flows",
    icon: "utility:flow",
    target: "/lightning/setup/Flows/home",
    accent: "#2e844a"
  },
  {
    id: "q4",
    label: "Check Limits",
    icon: "utility:metrics",
    target: "/lightning/setup/SystemOverview/home",
    accent: "#dd7a01"
  },
  {
    id: "q5",
    label: "Storage",
    icon: "utility:database",
    target: "/lightning/setup/CompanyResourceDisk/home",
    accent: "#0d9dda"
  },
  {
    id: "q6",
    label: "Integrations",
    icon: "utility:connected_apps",
    target: "/lightning/setup/NamedCredential/home",
    accent: "#0176d3"
  },
  {
    id: "q7",
    label: "Deployments",
    icon: "utility:package",
    target: "/lightning/setup/DeployStatus/home",
    accent: "#9050e9"
  },
  {
    id: "q8",
    label: "View Alerts",
    icon: "utility:warning",
    target: "/lightning/setup/SecurityHealthCheck/home",
    accent: "#ea001e"
  }
];

export default class AccQuickActions extends LightningElement {
  get actions() {
    return ACTIONS.map((action) => ({
      ...action,
      iconStyle: `--sds-c-icon-color-foreground-default:${action.accent};--sds-c-icon-color-foreground:${action.accent};`
    }));
  }
}
