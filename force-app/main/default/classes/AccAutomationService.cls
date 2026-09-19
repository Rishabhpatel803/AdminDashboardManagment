/**
 * Section 5 - Automation Overview, sourced from FlowDefinitionView, ApexClass,
 * ApexTrigger, CronTrigger and AsyncApexJob.
 *
 * Job counts use the specification's "Last 24 Hours" window for failures.
 * Failed flow interviews are not exposed to SOQL, so that column reports
 * unavailable rather than zero.
 */
public with sharing class AccAutomationService {
  private static final Integer PENALTY_FAILED_SCHEDULED_JOB = 5;
  private static final Integer PENALTY_FAILED_BATCH_JOB = 5;

  public static AccModel.AutomationSection build() {
    AccModel.AutomationSection section = new AccModel.AutomationSection();
    Datetime since = Datetime.now().addHours(-24);

    Integer flowsTotal = AccQuery.countOrNull(
      'SELECT COUNT() FROM FlowDefinitionView'
    );
    Integer flowsActive = AccQuery.countOrNull(
      'SELECT COUNT() FROM FlowDefinitionView WHERE IsActive = true'
    );
    Integer apexClasses = AccQuery.countOrNull('SELECT COUNT() FROM ApexClass');
    Integer triggersTotal = AccQuery.countOrNull(
      'SELECT COUNT() FROM ApexTrigger'
    );
    Integer triggersActive = AccQuery.countOrNull(
      'SELECT COUNT() FROM ApexTrigger WHERE Status = \'Active\''
    );
    Integer cronTotal = AccQuery.countOrNull('SELECT COUNT() FROM CronTrigger');
    Integer cronWaiting = AccQuery.countOrNull(
      'SELECT COUNT() FROM CronTrigger WHERE State = \'WAITING\''
    );

    Integer batchTotal = asyncCount('BatchApex', null, since);
    Integer batchDone = asyncCount('BatchApex', 'Completed', since);
    Integer batchFailed = asyncCount('BatchApex', 'Failed', since);
    Integer queueableTotal = asyncCount('Queueable', null, since);
    Integer queueableFailed = asyncCount('Queueable', 'Failed', since);
    Integer scheduledFailed = asyncCount('ScheduledApex', 'Failed', since);

    /* --- inventory table ---------------------------------------------- */

    section.inventory.add(
      row(
        'Flows',
        flowsTotal,
        flowsActive,
        null,
        'Flow interview failures are not queryable.'
      )
    );
    section.inventory.add(row('Apex Classes', apexClasses, null, null, null));
    section.inventory.add(
      row('Apex Triggers', triggersTotal, triggersActive, null, null)
    );
    section.inventory.add(
      row('Scheduled Jobs', cronTotal, cronWaiting, scheduledFailed, null)
    );
    section.inventory.add(
      row('Batch Jobs', batchTotal, batchDone, batchFailed, null)
    );
    section.inventory.add(
      row('Queueable Jobs', queueableTotal, null, queueableFailed, null)
    );

    /* --- status panel ------------------------------------------------- */

    if (flowsActive == null) {
      section.panel.add(
        panelRow(
          'p1',
          'Flow Status Unavailable',
          AccStatus.INFO,
          'utility:info',
          true
        )
      );
    } else {
      section.panel.add(
        panelRow(
          'p1',
          flowsActive + ' Active Flows',
          AccStatus.HEALTHY,
          'utility:check',
          false
        )
      );
    }

    section.panel.add(
      panelRow(
        'p2',
        'Flow Failures Unavailable',
        AccStatus.INFO,
        'utility:info',
        true
      )
    );

    section.panel.add(
      countPanelRow(
        'p3',
        scheduledFailed,
        'Scheduled Jobs Failed',
        'Scheduled Jobs Normal'
      )
    );
    section.panel.add(
      countPanelRow(
        'p4',
        batchFailed,
        'Batch Jobs Failed',
        'Batch Processing Normal'
      )
    );

    /* --- score -------------------------------------------------------- */

    Integer deduction = 0;
    if (scheduledFailed != null) {
      deduction += scheduledFailed * PENALTY_FAILED_SCHEDULED_JOB;
    }
    if (batchFailed != null) {
      deduction += batchFailed * PENALTY_FAILED_BATCH_JOB;
    }

    if (scheduledFailed == null && batchFailed == null) {
      section.unavailable = true;
      section.unavailableReason = 'AsyncApexJob is not readable by this user.';
      section.status = AccStatus.INFO;
    } else {
      section.score = Math.max(0, 100 - deduction);
      section.status = AccStatus.fromScore(section.score);
    }

    return section;
  }

  /* ==========================================================================
   * Helpers
   * ========================================================================== */

  private static Integer asyncCount(
    String jobType,
    String status,
    Datetime since
  ) {
    try {
      if (status == null) {
        return [
          SELECT COUNT()
          FROM AsyncApexJob
          WHERE JobType = :jobType AND CreatedDate >= :since
        ];
      }
      return [
        SELECT COUNT()
        FROM AsyncApexJob
        WHERE JobType = :jobType AND Status = :status AND CreatedDate >= :since
      ];
    } catch (Exception e) {
      return null;
    }
  }

  private static AccModel.AutomationRow row(
    String label,
    Integer total,
    Integer active,
    Integer errors,
    String errorNote
  ) {
    return new AccModel.AutomationRow(
      label,
      total == null ? 'N/A' : AccStatus.number(total),
      active == null ? '-' : AccStatus.number(active),
      errors == null ? '-' : AccStatus.number(errors),
      errors != null && errors > 0
    );
  }

  private static AccModel.Tile panelRow(
    String id,
    String label,
    String status,
    String icon,
    Boolean unavailable
  ) {
    AccModel.Tile tile = new AccModel.Tile(id, label, label, status);
    tile.icon = icon;
    tile.unavailable = unavailable;
    return tile;
  }

  /** Reports the failure count when there is one, otherwise the healthy label. */
  private static AccModel.Tile countPanelRow(
    String id,
    Integer failed,
    String failLabel,
    String okLabel
  ) {
    if (failed == null) {
      return panelRow(
        id,
        okLabel + ' Unavailable',
        AccStatus.INFO,
        'utility:info',
        true
      );
    }
    if (failed > 0) {
      return panelRow(
        id,
        failed + ' ' + failLabel,
        AccStatus.CRITICAL,
        'utility:error',
        false
      );
    }
    return panelRow(id, okLabel, AccStatus.HEALTHY, 'utility:check', false);
  }
}
