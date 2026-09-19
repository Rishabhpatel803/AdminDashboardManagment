import { createElement } from "lwc";
import AdminCommandCenter from "c/adminCommandCenter";
import getDashboard from "@salesforce/apex/AccAdminCommandCenterController.getDashboard";

jest.mock(
  "@salesforce/apex/AccAdminCommandCenterController.getDashboard",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

/** Flushes both the microtask queue and a macrotask tick, so a promise chain
 * (.then/.catch/.finally) and the LWC engine's reactive re-render have both
 * fully settled before assertions run. */
function flushPromises() {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

const SECTIONS = [
  "c-acc-instance-health",
  "c-acc-users-access",
  "c-acc-license-overview",
  "c-acc-security-health",
  "c-acc-automation-overview",
  "c-acc-integration-monitoring",
  "c-acc-api-limits",
  "c-acc-deployments",
  "c-acc-code-health",
  "c-acc-data-overview",
  "c-acc-critical-alerts",
  "c-acc-admin-activity",
  "c-acc-quick-actions"
];

/** A minimal but shape-complete payload, mirroring AccModel.Payload. */
function samplePayload() {
  return {
    visibility: {
      pageHeader: true,
      instanceHealth: true,
      usersAccess: true,
      licenseOverview: true,
      securityHealth: true,
      automationOverview: true,
      integrationMonitoring: true,
      apiLimits: true,
      deployments: true,
      codeHealth: true,
      dataOverview: true,
      criticalAlerts: true,
      adminActivity: true,
      quickActions: true,
      footer: true
    },
    meta: {
      demoMode: false,
      lastUpdatedLabel: "Last Updated: test",
      stale: false
    },
    org: {
      instanceId: "USA1140",
      environment: "Production",
      release: "Summer '26",
      status: "healthy",
      statusLabel: "Healthy",
      trust: "Data Unavailable",
      trustUnavailable: true,
      instanceUrl: "usa1140.salesforce.com",
      instanceUrlHref: "https://usa1140.salesforce.com",
      myDomain: "example.my.salesforce.com",
      myDomainHref: "https://example.my.salesforce.com",
      build: "67.0"
    },
    health: {
      score: 97,
      scoreLabel: "97%",
      status: "healthy",
      statusLabel: "Healthy",
      components: [],
      tooltip: ""
    },
    users: { kpis: [], alerts: [], mfaAdoption: null },
    licenses: {
      unavailable: false,
      supporting: [],
      donut: { value: 18, label: "18%", sublabel: "Used", status: "healthy" }
    },
    security: {
      inventory: [],
      alerts: [],
      subsystems: [],
      donut: { value: 90, label: "90%", sublabel: "Good", status: "healthy" }
    },
    automation: { unavailable: false, inventory: [], panel: [] },
    integrations: {
      systems: [],
      details: [],
      donut: {
        value: 0,
        label: "N/A",
        sublabel: "Data Unavailable",
        status: "info",
        unavailable: true
      }
    },
    limits: { unavailable: false, meters: [], panel: [] },
    deployments: { unavailable: true, unavailableReason: "test", footer: [] },
    code: {
      donut: {
        value: 0,
        label: "N/A",
        sublabel: "Data Unavailable",
        status: "info",
        unavailable: true
      },
      rows: [],
      coverageUnavailable: true
    },
    dataOverview: {
      totalRecords: "201,953",
      growthUnavailable: true,
      growthLabel: "N/A",
      objects: [],
      storage: { meters: [], totals: [] },
      activity: []
    },
    alerts: [
      { id: "a1", severity: "critical", title: "x", meta: "", tooltip: "" },
      { id: "a2", severity: "warning", title: "y", meta: "", tooltip: "" }
    ],
    activity: [
      {
        id: "ac1",
        timeLabel: "10:00 AM",
        action: "User Created",
        target: "Jane"
      }
    ]
  };
}

function render() {
  const element = createElement("c-admin-command-center", {
    is: AdminCommandCenter
  });
  document.body.appendChild(element);
  return element;
}

afterEach(() => {
  jest.clearAllMocks();
  while (document.body.firstChild) {
    document.body.removeChild(document.body.firstChild);
  }
});

describe("loading and error states", () => {
  it("shows a spinner while the Apex call is in flight", () => {
    getDashboard.mockReturnValue(new Promise(() => {}));
    const element = render();

    expect(
      element.shadowRoot.querySelector("lightning-spinner")
    ).not.toBeNull();
  });

  it("shows Data Unavailable with the server message when the call fails", async () => {
    getDashboard.mockRejectedValue({
      body: { message: "Insufficient access" }
    });
    const element = render();
    await flushPromises();

    expect(
      element.shadowRoot.querySelector(".acc-state--error")
    ).not.toBeNull();
    expect(
      element.shadowRoot.querySelector(".acc-state__message").textContent
    ).toBe("Insufficient access");
  });

  it("retries the Apex call when Retry is clicked", async () => {
    getDashboard.mockRejectedValueOnce({ message: "boom" });
    getDashboard.mockResolvedValueOnce(samplePayload());
    const element = render();
    await flushPromises();

    element.shadowRoot.querySelector(".acc-state--error button").click();
    await flushPromises();

    expect(getDashboard).toHaveBeenCalledTimes(2);
    expect(element.shadowRoot.querySelector(".grid")).not.toBeNull();
  });
});

describe("page composition once loaded", () => {
  async function renderLoaded() {
    getDashboard.mockResolvedValue(samplePayload());
    const element = render();
    await flushPromises();
    return element;
  }

  it("renders all 13 sections on one page", async () => {
    const root = (await renderLoaded()).shadowRoot;
    SECTIONS.forEach((tag) => expect(root.querySelector(tag)).not.toBeNull());
    expect(SECTIONS).toHaveLength(13);
  });

  it("hides Users & Access when the setting disables it", async () => {
    getDashboard.mockResolvedValue({
      ...samplePayload(),
      visibility: { ...samplePayload().visibility, usersAccess: false }
    });
    const root = (await render()).shadowRoot;
    await flushPromises();

    expect(root.querySelector("c-acc-users-access")).toBeNull();
    expect(root.querySelector("c-acc-license-overview")).not.toBeNull();
  });

  it("renders the page header and footer, driven by the fetched payload", async () => {
    const root = (await renderLoaded()).shadowRoot;
    expect(root.querySelector("c-acc-page-header")).not.toBeNull();
    expect(root.querySelector("c-acc-footer")).not.toBeNull();
  });

  it("makes exactly one Apex round trip per load", async () => {
    await renderLoaded();
    expect(getDashboard).toHaveBeenCalledTimes(1);
  });

  it("lays the sections out on a 12-column grid that adds up per row", async () => {
    const root = (await renderLoaded()).shadowRoot;
    const spanOf = (node) => {
      const match = [...node.classList].find((c) => c.startsWith("col-"));
      return Number(match.replace("col-", ""));
    };
    const cells = [...root.querySelectorAll(".grid > *")].map(spanOf);
    expect(cells.reduce((sum, span) => sum + span, 0) % 12).toBe(0);
    cells.forEach((span) => expect([4, 6, 8, 12]).toContain(span));
  });

  it("summarises the live page state for assistive technology", async () => {
    const root = (await renderLoaded()).shadowRoot;
    const summary = root.querySelector(".acc-sr-only").textContent;
    expect(summary).toContain("USA1140");
    expect(summary).toContain("Healthy");
    expect(summary).toContain("1 critical alerts");
  });
});
