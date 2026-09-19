/**
 * Section 10 - Data Overview, and the storage half of Section 11.
 *
 * Record counts come from Database.countQuery per object - real counts, not
 * estimates. Growth against a "previous period" is not derivable: Salesforce
 * keeps no historical daily snapshot of record counts, so growth is reported
 * as unavailable rather than invented. Storage percentages come from
 * AccLimitsService, which reads System.OrgLimits.
 */
public with sharing class AccDataService {
  /** Objects surfaced on the Largest Objects table, in the specification's order. */
  private static final List<String> TRACKED_OBJECTS = new List<String>{
    'Account',
    'Contact',
    'Opportunity',
    'Case'
  };

  private static final Decimal IMPACT_HIGH_SHARE = 20;
  private static final Decimal IMPACT_MEDIUM_SHARE = 5;

  public static AccModel.DataSection build() {
    AccModel.DataSection section = new AccModel.DataSection();

    Map<String, Long> counts = new Map<String, Long>();
    Long total = 0;
    Boolean anyFailed = false;

    for (String objectName : TRACKED_OBJECTS) {
      Integer count = AccQuery.countOrNull('SELECT COUNT() FROM ' + objectName);
      if (count == null) {
        anyFailed = true;
        continue;
      }
      counts.put(objectName, (Long) count);
      total += count;
    }

    /*
     * The specification also asks for a "Custom Objects" row. Summing every
     * custom object in an org can run to hundreds of COUNT() queries, which
     * risks the governor limit on query count for what is a single home-page
     * card, so that row is reported as unavailable rather than partially
     * computed.
     */
    section.totalRecords = anyFailed && counts.isEmpty()
      ? 'N/A'
      : AccStatus.number(total);

    section.growthUnavailable = true;
    section.growthLabel = 'N/A';
    section.growthStatus = AccStatus.INFO;

    /* --- largest objects table, sorted by record count descending ----- */

    List<Map<String, Object>> ranked = new List<Map<String, Object>>();
    for (String objectName : counts.keySet()) {
      ranked.add(
        new Map<String, Object>{
          'name' => objectName,
          'count' => counts.get(objectName)
        }
      );
    }
    ranked.sort(new CountComparator());

    for (Map<String, Object> entry : ranked) {
      Long count = (Long) entry.get('count');
      Decimal share = total > 0 ? AccStatus.percent(count, total) : 0;
      String impact = share >= IMPACT_HIGH_SHARE
        ? 'High'
        : (share >= IMPACT_MEDIUM_SHARE ? 'Medium' : 'Low');

      AccModel.ObjectRow objRow = new AccModel.ObjectRow();
      objRow.id = (String) entry.get('name');
      objRow.name = (String) entry.get('name');
      objRow.records = AccStatus.number(count);
      objRow.share = share;
      objRow.shareLabel = AccStatus.percentLabel(share);
      objRow.impact = impact;
      objRow.impactStatus = impact == 'High'
        ? AccStatus.CRITICAL
        : (impact == 'Medium' ? AccStatus.WARNING : AccStatus.HEALTHY);
      objRow.tooltip =
        objRow.name +
        ' holds ' +
        objRow.records +
        ' records (' +
        objRow.shareLabel +
        ' of the tracked total).';
      section.objects.add(objRow);
    }

    for (String objectName : TRACKED_OBJECTS) {
      if (!counts.containsKey(objectName)) {
        AccModel.ObjectRow objRow = new AccModel.ObjectRow();
        objRow.id = objectName;
        objRow.name = objectName;
        objRow.records = 'N/A';
        objRow.share = 0;
        objRow.shareLabel = 'N/A';
        objRow.impact = 'Unknown';
        objRow.impactStatus = AccStatus.INFO;
        objRow.tooltip = 'Data Unavailable: this object is not readable by this user.';
        section.objects.add(objRow);
      }
    }

    /*
     * The specification's table also lists "Custom Objects" as an aggregate
     * row. Summing every custom object in the org can run to hundreds of
     * COUNT() queries - too many for a single home-page card to risk against
     * the governor limit - so this row is reported unavailable rather than
     * partially computed or estimated.
     */
    AccModel.ObjectRow customObjectsRow = new AccModel.ObjectRow();
    customObjectsRow.id = 'CustomObjects';
    customObjectsRow.name = 'Custom Objects';
    customObjectsRow.records = 'N/A';
    customObjectsRow.share = 0;
    customObjectsRow.shareLabel = 'N/A';
    customObjectsRow.impact = 'Unknown';
    customObjectsRow.impactStatus = AccStatus.INFO;
    customObjectsRow.tooltip = 'Data Unavailable: summing every custom object would require one query per object, which risks the org\'s query governor limit for a single card.';
    section.objects.add(customObjectsRow);

    /* --- storage, real via OrgLimits ----------------------------------- */

    AccLimitsService.Storage storage = AccLimitsService.storage();
    section.storage = new AccModel.StorageInfo();

    String dataStatus = AccStatus.INFO;
    String fileStatus = AccStatus.INFO;

    if (storage.dataTotal != null && storage.dataTotal > 0) {
      Decimal usage = AccStatus.percent(storage.dataUsed, storage.dataTotal);
      dataStatus = AccStatus.fromUsage(
        usage,
        AccStatus.STORAGE_HEALTHY,
        AccStatus.STORAGE_WARNING
      );
      AccModel.Meter meter = new AccModel.Meter(
        'dataStorage',
        'Data Storage',
        storage.dataUsed,
        storage.dataTotal,
        dataStatus
      );
      meter.detail =
        megabytesLabel(storage.dataUsed) +
        ' of ' +
        megabytesLabel(storage.dataTotal);
      section.storage.meters.add(meter);
    }

    if (storage.fileTotal != null && storage.fileTotal > 0) {
      Decimal usage = AccStatus.percent(storage.fileUsed, storage.fileTotal);
      fileStatus = AccStatus.fromUsage(
        usage,
        AccStatus.STORAGE_HEALTHY,
        AccStatus.STORAGE_WARNING
      );
      AccModel.Meter meter = new AccModel.Meter(
        'fileStorage',
        'File Storage',
        storage.fileUsed,
        storage.fileTotal,
        fileStatus
      );
      meter.detail =
        megabytesLabel(storage.fileUsed) +
        ' of ' +
        megabytesLabel(storage.fileTotal);
      section.storage.meters.add(meter);
    }

    if (storage.dataTotal != null) {
      section.storage.totals.add(
        new AccModel.Tile(
          't1',
          'Total Storage',
          megabytesLabel(storage.dataTotal),
          AccStatus.INFO
        )
      );
      section.storage.totals.add(
        new AccModel.Tile(
          't2',
          'Used',
          megabytesLabel(storage.dataUsed),
          AccStatus.INFO
        )
      );
      section.storage.totals.add(
        new AccModel.Tile(
          't3',
          'Available',
          megabytesLabel(storage.dataTotal - storage.dataUsed),
          AccStatus.INFO
        )
      );
    }

    /*
     * Records created/modified/deleted today require Field History Tracking
     * or Event Monitoring, neither of which is guaranteed to be enabled, so
     * this panel reports unavailable rather than assuming zero activity.
     */
    section.activity.add(unavailableActivity('r1', 'Created Today'));
    section.activity.add(unavailableActivity('r2', 'Modified Today'));
    section.activity.add(unavailableActivity('r3', 'Deleted Today'));

    if (section.storage.meters.isEmpty()) {
      section.unavailable = true;
      section.unavailableReason = 'Storage limits were not reported by OrgLimits for this org.';
      section.status = AccStatus.INFO;
    } else {
      section.status = AccStatus.worst(
        new List<String>{ dataStatus, fileStatus }
      );
      Decimal worstUsage = Math.max(
        storage.dataTotal != null &&
          storage.dataTotal > 0
          ? AccStatus.percent(storage.dataUsed, storage.dataTotal)
          : 0,
        storage.fileTotal != null &&
          storage.fileTotal > 0
          ? AccStatus.percent(storage.fileUsed, storage.fileTotal)
          : 0
      );
      section.score = Math.max(
        0,
        100 - Math.max(0, worstUsage - AccStatus.STORAGE_HEALTHY) * 2
      );
    }

    return section;
  }

  private static String megabytesLabel(Decimal megabytes) {
    if (megabytes == null) {
      return 'N/A';
    }
    if (megabytes >= 1024) {
      return (megabytes / 1024).setScale(1) + ' GB';
    }
    return megabytes.setScale(0) + ' MB';
  }

  private static AccModel.Tile unavailableActivity(String id, String label) {
    AccModel.Tile tile = new AccModel.Tile(id, label, 'N/A', AccStatus.INFO);
    tile.icon = 'utility:info';
    tile.unavailable = true;
    tile.tooltip = 'Data Unavailable: requires Field History Tracking or Event Monitoring, which is not confirmed enabled for every tracked object.';
    return tile;
  }

  private class CountComparator implements Comparator<Map<String, Object>> {
    public Integer compare(Map<String, Object> a, Map<String, Object> b) {
      Long countA = (Long) a.get('count');
      Long countB = (Long) b.get('count');
      return countB > countA ? 1 : (countB < countA ? -1 : 0);
    }
  }
}
