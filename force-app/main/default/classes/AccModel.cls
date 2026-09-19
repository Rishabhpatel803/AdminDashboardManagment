/**
 * AccModel - the wire payload for the Admin Command Center.
 *
 * A small set of reusable DTOs shared across all 13 sections, so the shape the
 * LWCs consume is consistent and every value arrives pre-calculated and
 * pre-formatted by the server. Nothing on the client recomputes a percentage.
 *
 * Sections whose data cannot be retrieved from Apex set `unavailable = true`
 * and carry an `unavailableReason`, which the UI renders as the
 * specification's "Data Unavailable" state instead of inventing a number.
 */
public with sharing class AccModel {
  /* ==========================================================================
   * Reusable primitives
   * ========================================================================== */

  /** A labelled value with a status - KPIs, inventory counts, alert rows. */
  public class Tile {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String value;
    @AuraEnabled
    public Integer count;
    @AuraEnabled
    public String icon;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String statusLabel;
    @AuraEnabled
    public String tooltip;
    @AuraEnabled
    public Boolean wide;
    @AuraEnabled
    public String subValue;
    @AuraEnabled
    public Boolean unavailable;

    public Tile(String id, String label, String value, String status) {
      this.id = id;
      this.label = label;
      this.value = value;
      this.status = status;
      this.statusLabel = AccStatus.label(status);
      this.wide = false;
      this.unavailable = false;
    }
  }

  /** One slice of a segmented donut. */
  public class Segment {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public Integer value;
    @AuraEnabled
    public String status;

    public Segment(String id, Integer value, String status) {
      this.id = id;
      this.value = value;
      this.status = status;
    }
  }

  /** A donut chart: percentage, status label and the maths behind it. */
  public class Donut {
    @AuraEnabled
    public Decimal value;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String sublabel;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String tooltip;
    @AuraEnabled
    public List<Segment> segments;
    @AuraEnabled
    public Boolean unavailable;

    public Donut(
      Decimal value,
      String sublabel,
      String status,
      String tooltip
    ) {
      this.value = value;
      this.label = AccStatus.percentLabel(value);
      this.sublabel = sublabel;
      this.status = status;
      this.tooltip = tooltip;
      this.unavailable = false;
    }
  }

  /** A progress bar. `usage` is always current / maximum x 100. */
  public class Meter {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public Decimal usage;
    @AuraEnabled
    public String usageLabel;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String statusLabel;
    @AuraEnabled
    public String counts;
    @AuraEnabled
    public String detail;
    @AuraEnabled
    public String tooltip;

    public Meter(
      String id,
      String label,
      Decimal current,
      Decimal maximum,
      String status
    ) {
      this.id = id;
      this.label = label;
      this.usage = AccStatus.percent(current, maximum);
      this.usageLabel = AccStatus.percentLabel(this.usage);
      this.status = status;
      this.statusLabel = status == AccStatus.HEALTHY
        ? 'Normal'
        : AccStatus.label(status);
    }
  }

  /* ==========================================================================
   * Section payloads
   * ========================================================================== */

  public class OrgInfo {
    @AuraEnabled
    public String instanceId;
    @AuraEnabled
    public String orgName;
    @AuraEnabled
    public String environment;
    @AuraEnabled
    public String release;
    @AuraEnabled
    public String trust;
    @AuraEnabled
    public String trustStatus;
    @AuraEnabled
    public Boolean trustUnavailable;
    @AuraEnabled
    public String instanceUrl;
    @AuraEnabled
    public String instanceUrlHref;
    @AuraEnabled
    public String myDomain;
    @AuraEnabled
    public String myDomainHref;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String statusLabel;
    @AuraEnabled
    public String build;
    @AuraEnabled
    public Boolean isSandbox;
  }

  /** Automation inventory table row. */
  public class AutomationRow {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String total;
    @AuraEnabled
    public String active;
    @AuraEnabled
    public String errors;
    @AuraEnabled
    public Boolean hasErrors;

    public AutomationRow(
      String label,
      String total,
      String active,
      String errors,
      Boolean hasErrors
    ) {
      this.id = label;
      this.label = label;
      this.total = total;
      this.active = active;
      this.errors = errors;
      this.hasErrors = hasErrors;
    }
  }

  /** Largest Objects table row. Doubles as a horizontal bar via `share`. */
  public class ObjectRow {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String records;
    @AuraEnabled
    public Decimal share;
    @AuraEnabled
    public String shareLabel;
    @AuraEnabled
    public String impact;
    @AuraEnabled
    public String impactStatus;
    @AuraEnabled
    public String tooltip;
  }

  public class Deployment {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String environment;
    @AuraEnabled
    public String whenLabel;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String outcome;
    @AuraEnabled
    public Integer validationErrors;
    @AuraEnabled
    public String validationLabel;
    @AuraEnabled
    public Boolean hasValidationErrors;
  }

  public class Alert {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String category;
    @AuraEnabled
    public String severity;
    @AuraEnabled
    public String severityLabel;
    @AuraEnabled
    public String timestamp;
    @AuraEnabled
    public Datetime occurredAt;
    @AuraEnabled
    public String meta;
    @AuraEnabled
    public String description;
    @AuraEnabled
    public String action;
    @AuraEnabled
    public String tooltip;
  }

  public class Activity {
    @AuraEnabled
    public String id;
    /** Named timeLabel because `time` is a reserved identifier in Apex. */
    @AuraEnabled
    public String timeLabel;
    @AuraEnabled
    public String action;
    @AuraEnabled
    public String target;
    @AuraEnabled
    public String icon;
    @AuraEnabled
    public String status;
  }

  /* ==========================================================================
   * Section wrappers
   * ========================================================================== */

  /*
   * NOTE: these section classes deliberately repeat the four common fields
   * (unavailable / unavailableReason / score / status) rather than inheriting
   * them from a shared base. Apex does not reliably serialise INHERITED
   * @AuraEnabled members into the LWC wire payload, so a base class would
   * silently drop them on the client.
   */

  public class UsersSection {
    @AuraEnabled
    public Boolean unavailable = false;
    @AuraEnabled
    public String unavailableReason;
    @AuraEnabled
    public Decimal score;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public List<Tile> kpis = new List<Tile>();
    @AuraEnabled
    public List<Tile> alerts = new List<Tile>();
    @AuraEnabled
    public Decimal mfaAdoption;
  }

  public class LicenseSection {
    @AuraEnabled
    public Boolean unavailable = false;
    @AuraEnabled
    public String unavailableReason;
    @AuraEnabled
    public Decimal score;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public Tile primary;
    @AuraEnabled
    public List<Tile> supporting = new List<Tile>();
    @AuraEnabled
    public Donut donut;
    @AuraEnabled
    public String primaryCountLabel;
    @AuraEnabled
    public String primaryAvailableLabel;
    @AuraEnabled
    public String primaryName;
  }

  public class SecuritySection {
    @AuraEnabled
    public Boolean unavailable = false;
    @AuraEnabled
    public String unavailableReason;
    @AuraEnabled
    public Decimal score;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public List<Tile> inventory = new List<Tile>();
    @AuraEnabled
    public List<Tile> alerts = new List<Tile>();
    @AuraEnabled
    public List<Tile> subsystems = new List<Tile>();
    @AuraEnabled
    public Donut donut;
  }

  public class AutomationSection {
    @AuraEnabled
    public Boolean unavailable = false;
    @AuraEnabled
    public String unavailableReason;
    @AuraEnabled
    public Decimal score;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public List<AutomationRow> inventory = new List<AutomationRow>();
    @AuraEnabled
    public List<Tile> panel = new List<Tile>();
  }

  public class IntegrationSection {
    @AuraEnabled
    public Boolean unavailable = false;
    @AuraEnabled
    public String unavailableReason;
    @AuraEnabled
    public Decimal score;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public List<Tile> systems = new List<Tile>();
    @AuraEnabled
    public List<Tile> details = new List<Tile>();
    @AuraEnabled
    public List<Tile> legend = new List<Tile>();
    @AuraEnabled
    public List<Segment> segments = new List<Segment>();
    @AuraEnabled
    public Donut donut;
    @AuraEnabled
    public Boolean criticalSystemDown = false;
    @AuraEnabled
    public Boolean systemsUnavailable = false;
    @AuraEnabled
    public String systemsUnavailableReason;
  }

  public class LimitSection {
    @AuraEnabled
    public Boolean unavailable = false;
    @AuraEnabled
    public String unavailableReason;
    @AuraEnabled
    public Decimal score;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public List<Meter> meters = new List<Meter>();
    @AuraEnabled
    public List<Tile> panel = new List<Tile>();
  }

  public class DeploymentSection {
    @AuraEnabled
    public Boolean unavailable = false;
    @AuraEnabled
    public String unavailableReason;
    @AuraEnabled
    public Decimal score;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public List<Deployment> recent = new List<Deployment>();
    @AuraEnabled
    public List<Tile> footer = new List<Tile>();
    @AuraEnabled
    public String successRateLabel;
  }

  public class CodeSection {
    @AuraEnabled
    public Boolean unavailable = false;
    @AuraEnabled
    public String unavailableReason;
    @AuraEnabled
    public Decimal score;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public Donut donut;
    @AuraEnabled
    public List<Tile> rows = new List<Tile>();
    @AuraEnabled
    public Boolean coverageUnavailable = false;
    @AuraEnabled
    public String coverageUnavailableReason;
  }

  public class StorageInfo {
    @AuraEnabled
    public List<Meter> meters = new List<Meter>();
    @AuraEnabled
    public List<Tile> totals = new List<Tile>();
  }

  public class DataSection {
    @AuraEnabled
    public Boolean unavailable = false;
    @AuraEnabled
    public String unavailableReason;
    @AuraEnabled
    public Decimal score;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String totalRecords;
    @AuraEnabled
    public String growthLabel;
    @AuraEnabled
    public String growthStatus;
    @AuraEnabled
    public Boolean growthUnavailable = false;
    @AuraEnabled
    public List<ObjectRow> objects = new List<ObjectRow>();
    @AuraEnabled
    public StorageInfo storage = new StorageInfo();
    @AuraEnabled
    public List<Tile> activity = new List<Tile>();
  }

  public class HealthComponent {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String weight;
    @AuraEnabled
    public Integer score;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public Boolean counted;
  }

  public class HealthSection {
    @AuraEnabled
    public Decimal score;
    @AuraEnabled
    public String scoreLabel;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String statusLabel;
    @AuraEnabled
    public List<HealthComponent> components = new List<HealthComponent>();
    @AuraEnabled
    public String tooltip;
  }

  public class Meta {
    @AuraEnabled
    public Boolean demoMode = false;
    @AuraEnabled
    public String lastUpdated;
    @AuraEnabled
    public String lastUpdatedLabel;
    @AuraEnabled
    public Boolean stale = false;
  }

  /* ==========================================================================
   * Root payload
   * ========================================================================== */

  public class Visibility {
    @AuraEnabled
    public Boolean pageHeader = true;
    @AuraEnabled
    public Boolean instanceHealth = true;
    @AuraEnabled
    public Boolean usersAccess = true;
    @AuraEnabled
    public Boolean licenseOverview = true;
    @AuraEnabled
    public Boolean securityHealth = true;
    @AuraEnabled
    public Boolean automationOverview = true;
    @AuraEnabled
    public Boolean integrationMonitoring = true;
    @AuraEnabled
    public Boolean apiLimits = true;
    @AuraEnabled
    public Boolean deployments = true;
    @AuraEnabled
    public Boolean codeHealth = true;
    @AuraEnabled
    public Boolean dataOverview = true;
    @AuraEnabled
    public Boolean criticalAlerts = true;
    @AuraEnabled
    public Boolean adminActivity = true;
    @AuraEnabled
    public Boolean quickActions = true;
    @AuraEnabled
    public Boolean footer = true;
  }

  public class Payload {
    @AuraEnabled
    public Meta meta = new Meta();
    @AuraEnabled
    public Visibility visibility = new Visibility();
    @AuraEnabled
    public OrgInfo org;
    @AuraEnabled
    public HealthSection health;
    @AuraEnabled
    public UsersSection users;
    @AuraEnabled
    public LicenseSection licenses;
    @AuraEnabled
    public SecuritySection security;
    @AuraEnabled
    public AutomationSection automation;
    @AuraEnabled
    public IntegrationSection integrations;
    @AuraEnabled
    public LimitSection limits;
    @AuraEnabled
    public DeploymentSection deployments;
    @AuraEnabled
    public CodeSection code;
    @AuraEnabled
    public DataSection dataOverview;
    @AuraEnabled
    public List<Alert> alerts = new List<Alert>();
    @AuraEnabled
    public List<Activity> activity = new List<Activity>();
  }
}
