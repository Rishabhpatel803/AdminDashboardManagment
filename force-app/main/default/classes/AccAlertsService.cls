/**
 * Section 12 - Critical Alerts Center.
 *
 * Aggregates concrete findings already computed by the other section
 * services - it raises no new queries and invents no alert that is not
 * traceable to a real count. Sorted critical first, then warning, then info,
 * each group most-recent first (spec Sec 12 "Alert Priority").
 */
public with sharing class AccAlertsService {
  public static List<AccModel.Alert> build(AccModel.Payload payload) {
    List<AccModel.Alert> alerts = new List<AccModel.Alert>();
    Datetime now = Datetime.now();

    for (AccModel.Tile tile : payload.users.alerts) {
      addFromCount(
        alerts,
        tile,
        'Users',
        now,
        'Review the affected user accounts in Setup > Users.'
      );
    }

    for (AccModel.Tile tile : payload.security.alerts) {
      addFromCount(
        alerts,
        tile,
        'Security',
        now,
        'Review the affected security setting in Setup > Security.'
      );
    }

    if (payload.automation != null && !payload.automation.unavailable) {
      for (AccModel.Tile tile : payload.automation.panel) {
        if (
          tile.status == AccStatus.CRITICAL ||
          tile.status == AccStatus.WARNING
        ) {
          addAlert(
            alerts,
            'auto-' + tile.id,
            tile.label,
            'Automation',
            tile.status,
            now,
            'Open the failed job or flow interview and review the error.',
            'Review the failed job or flow interview in Setup > Automation.'
          );
        }
      }
    }

    if (payload.limits != null) {
      for (AccModel.Meter meter : payload.limits.meters) {
        if (
          meter.status == AccStatus.CRITICAL ||
          meter.status == AccStatus.WARNING
        ) {
          addAlert(
            alerts,
            'limit-' + meter.id,
            meter.label + ' at ' + meter.usageLabel,
            'API & Limits',
            meter.status,
            now,
            meter.label +
              ' usage is at ' +
              meter.usageLabel +
              ' of its allocation.',
            'Review usage in Setup > Company Information and plan capacity.'
          );
        }
      }
    }

    if (payload.dataOverview != null) {
      for (AccModel.Meter meter : payload.dataOverview.storage.meters) {
        if (
          meter.status == AccStatus.CRITICAL ||
          meter.status == AccStatus.WARNING
        ) {
          addAlert(
            alerts,
            'storage-' + meter.id,
            meter.label +
              ' Above ' +
              AccStatus.STORAGE_HEALTHY.intValue() +
              '%',
            'Storage',
            meter.status,
            now,
            meter.label +
              ' is at ' +
              meter.usageLabel +
              ' of the allocated storage.',
            'Archive old records or purchase additional storage.'
          );
        }
      }
    }

    if (
      payload.licenses != null &&
      !payload.licenses.unavailable &&
      payload.licenses.donut != null
    ) {
      String status = payload.licenses.donut.status;
      if (status == AccStatus.CRITICAL || status == AccStatus.WARNING) {
        addAlert(
          alerts,
          'license-utilisation',
          'License Utilization Above ' +
            AccStatus.LICENSE_HEALTHY.intValue() +
            '%',
          'Licenses',
          status,
          now,
          payload.licenses.primaryName +
            ' utilisation is at ' +
            payload.licenses.donut.label +
            '.',
          'Review licence assignment or procure additional licences.'
        );
      }
    }

    alerts.sort(new AlertComparator());
    return alerts;
  }

  private static void addFromCount(
    List<AccModel.Alert> alerts,
    AccModel.Tile tile,
    String category,
    Datetime now,
    String action
  ) {
    if (tile.unavailable == true || tile.count == null || tile.count <= 0) {
      return;
    }
    addAlert(
      alerts,
      category + '-' + tile.id,
      tile.count + ' ' + tile.label,
      category,
      tile.status == AccStatus.HEALTHY ? AccStatus.WARNING : tile.status,
      now,
      tile.count + ' ' + tile.label.toLowerCase() + ' detected.',
      action
    );
  }

  private static void addAlert(
    List<AccModel.Alert> alerts,
    String id,
    String title,
    String category,
    String severity,
    Datetime occurredAt,
    String description,
    String action
  ) {
    AccModel.Alert alert = new AccModel.Alert();
    alert.id = id;
    alert.title = title;
    alert.category = category;
    alert.severity = severity;
    alert.severityLabel = AccStatus.label(severity);
    alert.occurredAt = occurredAt;
    alert.timestamp = occurredAt.format('MMM d, yyyy hh:mm a');
    alert.meta = category + ' · ' + alert.timestamp;
    alert.description = description;
    alert.action = action;
    alert.tooltip = description + ' Recommended action: ' + action;
    alerts.add(alert);
  }

  private class AlertComparator implements Comparator<AccModel.Alert> {
    private final Map<String, Integer> rank = new Map<String, Integer>{
      AccStatus.CRITICAL => 0,
      AccStatus.WARNING => 1,
      AccStatus.INFO => 2,
      AccStatus.HEALTHY => 3
    };

    public Integer compare(AccModel.Alert a, AccModel.Alert b) {
      Integer rankA = rank.get(a.severity);
      Integer rankB = rank.get(b.severity);
      if (rankA != rankB) {
        return rankA - rankB;
      }
      if (b.occurredAt == a.occurredAt) {
        return 0;
      }
      return b.occurredAt > a.occurredAt ? 1 : -1;
    }
  }
}
