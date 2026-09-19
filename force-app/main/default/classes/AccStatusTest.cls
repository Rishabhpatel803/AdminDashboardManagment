@isTest
private class AccStatusTest {
  @isTest
  static void testUsageBanding() {
    System.assertEquals(
      AccStatus.HEALTHY,
      AccStatus.fromUsage(68, AccStatus.LIMIT_HEALTHY, AccStatus.LIMIT_WARNING)
    );
    System.assertEquals(
      AccStatus.HEALTHY,
      AccStatus.fromUsage(70, AccStatus.LIMIT_HEALTHY, AccStatus.LIMIT_WARNING)
    );
    System.assertEquals(
      AccStatus.WARNING,
      AccStatus.fromUsage(78, AccStatus.LIMIT_HEALTHY, AccStatus.LIMIT_WARNING)
    );
    System.assertEquals(
      AccStatus.CRITICAL,
      AccStatus.fromUsage(92, AccStatus.LIMIT_HEALTHY, AccStatus.LIMIT_WARNING)
    );
    System.assertEquals(
      AccStatus.INFO,
      AccStatus.fromUsage(
        null,
        AccStatus.LIMIT_HEALTHY,
        AccStatus.LIMIT_WARNING
      )
    );
  }

  @isTest
  static void testScoreBanding() {
    System.assertEquals(AccStatus.HEALTHY, AccStatus.fromScore(90));
    System.assertEquals(AccStatus.WARNING, AccStatus.fromScore(81));
    System.assertEquals(AccStatus.CRITICAL, AccStatus.fromScore(60));
  }

  @isTest
  static void testWorstStatusPriority() {
    System.assertEquals(
      AccStatus.CRITICAL,
      AccStatus.worst(
        new List<String>{
          AccStatus.HEALTHY,
          AccStatus.WARNING,
          AccStatus.CRITICAL
        }
      )
    );
    System.assertEquals(
      AccStatus.WARNING,
      AccStatus.worst(new List<String>{ AccStatus.HEALTHY, AccStatus.WARNING })
    );
    System.assertEquals(
      AccStatus.HEALTHY,
      AccStatus.worst(new List<String>{ AccStatus.HEALTHY, AccStatus.INFO })
    );
    // A lone info entry must not be promoted to healthy by the seed value.
    System.assertEquals(
      AccStatus.INFO,
      AccStatus.worst(new List<String>{ AccStatus.INFO })
    );
    System.assertEquals(AccStatus.HEALTHY, AccStatus.worst(new List<String>()));
  }

  @isTest
  static void testPercentArithmetic() {
    System.assertEquals(68.3, AccStatus.percent(102450, 150000).setScale(1));
    System.assertEquals(0, AccStatus.percent(10, 0));
    System.assertEquals(0, AccStatus.percent(null, 100));
    System.assertEquals('68%', AccStatus.percentLabel(68.3));
    System.assertEquals('-', AccStatus.percentLabel(null));
  }

  @isTest
  static void testNumberFormatting() {
    System.assertEquals('102,450', AccStatus.number(102450L));
    System.assertEquals('850', AccStatus.number(850L));
    System.assertEquals('-', AccStatus.number(null));
  }
}
