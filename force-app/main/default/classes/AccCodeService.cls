/**
 * Section 9 - Apex & Code Health.
 *
 * The Apex inventory is real (ApexClass, ApexTrigger, CronTrigger,
 * AsyncApexJob). Org-wide test coverage is not: ApexOrgWideCoverage and
 * ApexCodeCoverageAggregate are Tooling API objects and are not visible to
 * SOQL from Apex, so the coverage donut reports Data Unavailable and this
 * component is excluded from the weighted instance health score.
 */
public with sharing class AccCodeService {
  public static AccModel.CodeSection build() {
    AccModel.CodeSection section = new AccModel.CodeSection();
    Datetime since = Datetime.now().addHours(-24);

    Integer apexClasses = AccQuery.countOrNull('SELECT COUNT() FROM ApexClass');
    Integer triggers = AccQuery.countOrNull('SELECT COUNT() FROM ApexTrigger');
    Integer scheduled = AccQuery.countOrNull('SELECT COUNT() FROM CronTrigger');
    Integer batchJobs = asyncCount('BatchApex', since);
    Integer queueableJobs = asyncCount('Queueable', since);
    Integer failedJobs = failedAsync(since);

    section.rows.add(row('Apex Classes', apexClasses));
    section.rows.add(row('Triggers', triggers));
    section.rows.add(row('Scheduled Apex', scheduled));
    section.rows.add(row('Batch Jobs', batchJobs));
    section.rows.add(row('Queueable Jobs', queueableJobs));

    AccModel.Tile tests = new AccModel.Tile(
      'failedTests',
      'Failed Tests',
      'N/A',
      AccStatus.INFO
    );
    tests.unavailable = true;
    tests.tooltip = 'Data Unavailable: Apex test results are exposed through the Tooling API, not SOQL.';
    section.rows.add(tests);

    AccModel.Tile failed = row('Failed Jobs (24h)', failedJobs);
    if (failedJobs != null && failedJobs > 0) {
      failed.status = AccStatus.CRITICAL;
      failed.statusLabel = AccStatus.label(AccStatus.CRITICAL);
    }
    section.rows.add(failed);

    section.coverageUnavailable = true;
    section.coverageUnavailableReason = 'Org-wide test coverage lives in ApexOrgWideCoverage, a Tooling API object that Apex SOQL cannot read.';

    AccModel.Donut donut = new AccModel.Donut(
      0,
      'Data Unavailable',
      AccStatus.INFO,
      section.coverageUnavailableReason
    );
    donut.label = 'N/A';
    donut.unavailable = true;
    section.donut = donut;

    section.unavailable = true;
    section.unavailableReason = section.coverageUnavailableReason;
    section.status = failedJobs != null &&
      failedJobs > 0
      ? AccStatus.CRITICAL
      : AccStatus.INFO;

    return section;
  }

  private static Integer asyncCount(String jobType, Datetime since) {
    try {
      return [
        SELECT COUNT()
        FROM AsyncApexJob
        WHERE JobType = :jobType AND CreatedDate >= :since
      ];
    } catch (Exception e) {
      return null;
    }
  }

  private static Integer failedAsync(Datetime since) {
    try {
      return [
        SELECT COUNT()
        FROM AsyncApexJob
        WHERE Status = 'Failed' AND CreatedDate >= :since
      ];
    } catch (Exception e) {
      return null;
    }
  }

  private static AccModel.Tile row(String label, Integer value) {
    AccModel.Tile tile = new AccModel.Tile(
      label,
      label,
      value == null ? 'N/A' : AccStatus.number(value),
      AccStatus.INFO
    );
    tile.count = value;
    tile.unavailable = value == null;
    return tile;
  }
}
