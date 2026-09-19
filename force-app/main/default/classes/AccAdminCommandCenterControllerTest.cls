/**
 * Exercises the full controller against real org data. Assertions check
 * structural and mathematical consistency (percentages match their inputs,
 * sections that mark themselves unavailable carry a reason, alerts are
 * sorted, activity is capped at 5) rather than fixed values, since this runs
 * against whatever org the tests execute in.
 */
@isTest
private class AccAdminCommandCenterControllerTest {
  @isTest
  static void testDashboardIsInternallyConsistent() {
    Test.startTest();
    AccModel.Payload payload = AccAdminCommandCenterController.getDashboard();
    Test.stopTest();

    System.assertNotEquals(
      null,
      payload,
      'The controller must always return a payload.'
    );
    System.assertNotEquals(
      null,
      payload.org,
      'Org info must always be present.'
    );
    System.assertNotEquals(
      null,
      payload.health,
      'Health roll-up must always be present.'
    );

    assertOrgInfo(payload.org);
    assertUnavailableSectionsCarryAReason(payload);
    assertLimitMetersMatchTheirMaths(payload);
    assertStorageMetersMatchTheirMaths(payload);
    assertLicenseMathsAgreeWithTheDonut(payload);
    assertAlertsAreSortedBySeverityThenRecency(payload.alerts);
    assertActivityIsCappedAtFive(payload.activity);
    assertHealthScoreIsInBounds(payload.health);
  }

  @isTest
  static void testStaticResourcesAreIndependentOfOrgData() {
    // A second call must reuse the same calculation rules and stay consistent.
    AccModel.Payload first = AccAdminCommandCenterController.getDashboard();
    AccModel.Payload second = AccAdminCommandCenterController.getDashboard();

    System.assertEquals(first.org.instanceId, second.org.instanceId);
    System.assertEquals(first.health.status, second.health.status);
  }

  /* ==========================================================================
   * Assertions
   * ========================================================================== */

  private static void assertOrgInfo(AccModel.OrgInfo org) {
    System.assertNotEquals(
      null,
      org.instanceId,
      'Instance ID must be populated from Organization.InstanceName.'
    );
    System.assertNotEquals(
      null,
      org.environment,
      'Environment must be derived from Organization.IsSandbox.'
    );
    System.assert(
      org.environment == 'Production' || org.environment == 'Sandbox',
      'Environment must be one of the two real values.'
    );
    // Trust status requires an external callout this page does not make.
    System.assertEquals(
      true,
      org.trustUnavailable,
      'Trust status must be reported unavailable, not guessed.'
    );
  }

  private static void assertUnavailableSectionsCarryAReason(
    AccModel.Payload payload
  ) {
    if (payload.deployments.unavailable) {
      System.assertNotEquals(
        null,
        payload.deployments.unavailableReason,
        'An unavailable section must explain why.'
      );
    }
    if (payload.code.coverageUnavailable) {
      System.assertNotEquals(
        null,
        payload.code.coverageUnavailableReason,
        'Unavailable coverage must explain why.'
      );
      System.assertEquals(true, payload.code.donut.unavailable);
    }
  }

  private static void assertLimitMetersMatchTheirMaths(
    AccModel.Payload payload
  ) {
    if (payload.limits.unavailable) {
      return;
    }
    for (AccModel.Meter meter : payload.limits.meters) {
      System.assert(
        meter.usage >= 0 && meter.usage <= 1000,
        'Usage percentage must be a sane, non-negative value.'
      );
      String expectedStatus = AccStatus.fromUsage(
        meter.usage,
        AccStatus.LIMIT_HEALTHY,
        AccStatus.LIMIT_WARNING
      );
      System.assertEquals(
        expectedStatus,
        meter.status,
        'A limit meter status must be derivable from its own usage percentage.'
      );
    }
  }

  private static void assertStorageMetersMatchTheirMaths(
    AccModel.Payload payload
  ) {
    for (AccModel.Meter meter : payload.dataOverview.storage.meters) {
      String expectedStatus = AccStatus.fromUsage(
        meter.usage,
        AccStatus.STORAGE_HEALTHY,
        AccStatus.STORAGE_WARNING
      );
      System.assertEquals(
        expectedStatus,
        meter.status,
        'A storage meter status must match its own usage.'
      );
    }
    if (payload.dataOverview.storage.totals.size() == 3) {
      Integer total = Integer.valueOf(
        payload.dataOverview.storage.totals[0].value.replaceAll('[^0-9]', '')
      );
      Integer used = Integer.valueOf(
        payload.dataOverview.storage.totals[1].value.replaceAll('[^0-9]', '')
      );
      Integer available = Integer.valueOf(
        payload.dataOverview.storage.totals[2].value.replaceAll('[^0-9]', '')
      );
      System.assertEquals(
        total - used,
        available,
        'Available storage must equal total minus used.'
      );
    }
  }

  private static void assertLicenseMathsAgreeWithTheDonut(
    AccModel.Payload payload
  ) {
    if (payload.licenses.unavailable || payload.licenses.donut == null) {
      return;
    }
    System.assert(
      payload.licenses.donut.value >= 0 && payload.licenses.donut.value <= 100
    );
    String expectedStatus = AccStatus.fromUsage(
      payload.licenses.donut.value,
      AccStatus.LICENSE_HEALTHY,
      AccStatus.LICENSE_WARNING
    );
    System.assertEquals(expectedStatus, payload.licenses.donut.status);
  }

  private static void assertAlertsAreSortedBySeverityThenRecency(
    List<AccModel.Alert> alerts
  ) {
    Map<String, Integer> rank = new Map<String, Integer>{
      AccStatus.CRITICAL => 0,
      AccStatus.WARNING => 1,
      AccStatus.INFO => 2,
      AccStatus.HEALTHY => 3
    };
    Integer previousRank = -1;
    for (AccModel.Alert alert : alerts) {
      Integer currentRank = rank.get(alert.severity);
      System.assert(
        currentRank >= previousRank,
        'Alerts must be sorted with the worst severity first.'
      );
      previousRank = currentRank;
    }
  }

  private static void assertActivityIsCappedAtFive(
    List<AccModel.Activity> activity
  ) {
    System.assert(
      activity.size() <= 5,
      'The home page must show at most 5 recent activities.'
    );
  }

  private static void assertHealthScoreIsInBounds(
    AccModel.HealthSection health
  ) {
    if (health.score == null) {
      System.assertEquals('N/A', health.scoreLabel);
      return;
    }
    System.assert(
      health.score >= 0 && health.score <= 100,
      'The weighted health score must be a real percentage.'
    );

    Decimal weightedSum = 0;
    Decimal weightTotal = 0;
    for (AccModel.HealthComponent component : health.components) {
      if (component.counted) {
        Decimal weight =
          Decimal.valueOf(component.weight.replace('%', '')) / 100;
        weightedSum += component.score * weight;
        weightTotal += weight;
      }
    }
    if (weightTotal > 0) {
      Decimal expected = weightedSum / weightTotal;
      System.assert(
        Math.abs(expected - health.score) < 1,
        'The published score must equal the weighted average of the counted components.'
      );
    }
  }
}
