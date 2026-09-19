/**
 * Section 7 - API & System Limits, and Section 11 - Storage Utilisation.
 *
 * Both are sourced from System.OrgLimits, which reports real current usage
 * against the org's real allocation - including DataStorageMB and
 * FileStorageMB, the only supported way to read storage from Apex.
 *
 * Every meter is current / maximum x 100, so the bar width always equals the
 * number printed beside it.
 */
public with sharing class AccLimitsService {
  /** Candidate OrgLimits keys per metric; the first present key wins. */
  private static final Map<String, List<String>> LIMIT_KEYS = new Map<String, List<String>>{
    'api' => new List<String>{ 'DailyApiRequests' },
    'asyncApex' => new List<String>{
      'DailyAsyncApexExecutions',
      'DailyAsyncApexTests'
    },
    'platformEvents' => new List<String>{
      'DailyDeliveredPlatformEvents',
      'HourlyPublishedPlatformEvents',
      'HourlyPublishedStandardVolumePlatformEvents'
    },
    'email' => new List<String>{ 'SingleEmail', 'DailyWorkflowEmails' }
  };

  public class Storage {
    public Decimal dataUsed;
    public Decimal dataTotal;
    public Decimal fileUsed;
    public Decimal fileTotal;
  }

  /* ==========================================================================
   * Section 7 - API & System Limits
   * ========================================================================== */

  public static AccModel.LimitSection build() {
    AccModel.LimitSection section = new AccModel.LimitSection();
    Map<String, System.OrgLimit> orgLimits = safeLimits();

    if (orgLimits.isEmpty()) {
      section.unavailable = true;
      section.unavailableReason = 'System.OrgLimits returned no data for this org.';
      section.status = AccStatus.INFO;
      return section;
    }

    addMeter(section, orgLimits, 'api', 'API Requests', true);
    addMeter(section, orgLimits, 'platformEvents', 'Platform Events', false);
    addMeter(section, orgLimits, 'email', 'Email Usage', false);
    addMeter(section, orgLimits, 'asyncApex', 'Async Apex', false);

    /*
     * Apex CPU time is a per-transaction governor limit, not an org-wide
     * allocation, so there is no org-level percentage to report.
     */
    AccModel.Tile cpu = new AccModel.Tile(
      'apexCpu',
      'Apex CPU',
      'N/A',
      AccStatus.INFO
    );
    cpu.unavailable = true;
    cpu.tooltip = 'Data Unavailable: Apex CPU is a per-transaction governor limit, not an org-wide allocation.';

    List<String> statuses = new List<String>();
    for (AccModel.Meter meter : section.meters) {
      statuses.add(meter.status);
      AccModel.Tile panelTile = new AccModel.Tile(
        'panel-' + meter.id,
        meter.label,
        meter.statusLabel,
        meter.status
      );
      section.panel.add(panelTile);
    }
    section.panel.add(cpu);

    if (section.meters.isEmpty()) {
      section.unavailable = true;
      section.unavailableReason = 'No recognised limit metrics are available in this org.';
      section.status = AccStatus.INFO;
      return section;
    }

    section.status = AccStatus.worst(statuses);

    // All limits inside the healthy band scores 100; each point above costs 2.
    Decimal worstUsage = 0;
    for (AccModel.Meter meter : section.meters) {
      if (meter.usage > worstUsage) {
        worstUsage = meter.usage;
      }
    }
    section.score = Math.max(
      0,
      100 - Math.max(0, worstUsage - AccStatus.LIMIT_HEALTHY) * 2
    );
    return section;
  }

  /* ==========================================================================
   * Section 11 - Storage
   * ========================================================================== */

  public static Storage storage() {
    Map<String, System.OrgLimit> orgLimits = safeLimits();
    Storage result = new Storage();

    System.OrgLimit dataLimit = orgLimits.get('DataStorageMB');
    if (dataLimit != null) {
      result.dataUsed = dataLimit.getValue();
      result.dataTotal = dataLimit.getLimit();
    }

    System.OrgLimit fileLimit = orgLimits.get('FileStorageMB');
    if (fileLimit != null) {
      result.fileUsed = fileLimit.getValue();
      result.fileTotal = fileLimit.getLimit();
    }
    return result;
  }

  /** API usage percentage, reused by the Integration Details panel. */
  public static Decimal apiUsagePercent() {
    Map<String, System.OrgLimit> orgLimits = safeLimits();
    System.OrgLimit limitRow = resolve(orgLimits, 'api');
    if (limitRow == null || limitRow.getLimit() == 0) {
      return null;
    }
    return AccStatus.percent(limitRow.getValue(), limitRow.getLimit());
  }

  /* ==========================================================================
   * Helpers
   * ========================================================================== */

  private static Map<String, System.OrgLimit> cachedLimits;

  private static Map<String, System.OrgLimit> safeLimits() {
    if (cachedLimits != null) {
      return cachedLimits;
    }
    try {
      cachedLimits = OrgLimits.getMap();
    } catch (Exception e) {
      cachedLimits = new Map<String, System.OrgLimit>();
    }
    return cachedLimits;
  }

  private static System.OrgLimit resolve(
    Map<String, System.OrgLimit> orgLimits,
    String metric
  ) {
    for (String key : LIMIT_KEYS.get(metric)) {
      if (orgLimits.containsKey(key)) {
        return orgLimits.get(key);
      }
    }
    return null;
  }

  private static void addMeter(
    AccModel.LimitSection section,
    Map<String, System.OrgLimit> orgLimits,
    String metric,
    String label,
    Boolean showCounts
  ) {
    System.OrgLimit limitRow = resolve(orgLimits, metric);
    if (
      limitRow == null ||
      limitRow.getLimit() == null ||
      limitRow.getLimit() <= 0
    ) {
      return;
    }

    Decimal used = limitRow.getValue();
    Decimal maximum = limitRow.getLimit();
    String status = AccStatus.fromUsage(
      AccStatus.percent(used, maximum),
      AccStatus.LIMIT_HEALTHY,
      AccStatus.LIMIT_WARNING
    );

    AccModel.Meter meter = new AccModel.Meter(
      metric,
      label,
      used,
      maximum,
      status
    );
    if (showCounts) {
      meter.counts =
        AccStatus.number(used.longValue()) +
        ' / ' +
        AccStatus.number(maximum.longValue()) +
        ' (' +
        meter.usageLabel +
        ')';
    }
    meter.tooltip =
      'OrgLimits "' +
      limitRow.getName() +
      '": ' +
      AccStatus.number(used.longValue()) +
      ' of ' +
      AccStatus.number(maximum.longValue()) +
      ' used.';
    section.meters.add(meter);
  }
}
