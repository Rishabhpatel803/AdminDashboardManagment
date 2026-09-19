/**
 * AccStatus - the specification's status vocabulary and threshold bands.
 *
 * Every status shown on the Admin Command Center is produced here, so the
 * banding rules exist in exactly one place and are applied identically to
 * every metric.
 *
 * Status priority (spec "IMPORTANT STATUS PRIORITY RULE"):
 *   critical > warning > healthy > info
 */
public with sharing class AccStatus {
  public static final String HEALTHY = 'healthy';
  public static final String INFO = 'info';
  public static final String WARNING = 'warning';
  public static final String CRITICAL = 'critical';

  private static final Map<String, Integer> RANK = new Map<String, Integer>{
    CRITICAL => 3,
    WARNING => 2,
    HEALTHY => 1,
    INFO => 0
  };

  private static final Map<String, String> LABEL = new Map<String, String>{
    HEALTHY => 'Healthy',
    INFO => 'Info',
    WARNING => 'Warning',
    CRITICAL => 'Critical'
  };

  /* ==========================================================================
   * Threshold bands, lifted from the specification
   * ========================================================================== */

  /** Sec 7: 0-70 healthy, 71-85 warning, 86-100 critical. */
  public static final Decimal LIMIT_HEALTHY = 70;
  public static final Decimal LIMIT_WARNING = 85;

  /** Sec 11: below 70 healthy, 70-85 warning, above 85 critical. */
  public static final Decimal STORAGE_HEALTHY = 70;
  public static final Decimal STORAGE_WARNING = 85;

  /** Sec 3: below 80 healthy, 80-90 warning, above 90 critical. */
  public static final Decimal LICENSE_HEALTHY = 80;
  public static final Decimal LICENSE_WARNING = 90;

  /** Sec 2: 95-100 healthy, 80-94 warning, below 80 critical. */
  public static final Decimal MFA_HEALTHY = 95;
  public static final Decimal MFA_WARNING = 80;

  /** Sec 9: 90+ healthy, 80-89 warning, below 80 critical. */
  public static final Decimal COVERAGE_HEALTHY = 90;
  public static final Decimal COVERAGE_WARNING = 80;

  /** Sec 8: 95-100 healthy, 80-94 warning, below 80 critical. */
  public static final Decimal DEPLOY_HEALTHY = 95;
  public static final Decimal DEPLOY_WARNING = 80;

  /** Sec 1: 90-100 healthy, 75-89 warning, below 75 critical. */
  public static final Decimal SCORE_HEALTHY = 90;
  public static final Decimal SCORE_WARNING = 75;

  /** Sec 2: password expiry warning window, in days. */
  public static final Integer PASSWORD_EXPIRY_DAYS = 7;

  /* ==========================================================================
   * Banding
   * ========================================================================== */

  /** "More is worse" - usage and utilisation percentages. */
  public static String fromUsage(
    Decimal usage,
    Decimal healthyMax,
    Decimal warningMax
  ) {
    if (usage == null) {
      return INFO;
    }
    if (usage > warningMax) {
      return CRITICAL;
    }
    if (usage > healthyMax) {
      return WARNING;
    }
    return HEALTHY;
  }

  /** "More is better" - scores, coverage, adoption and success rates. */
  public static String fromScore(
    Decimal score,
    Decimal healthyMin,
    Decimal warningMin
  ) {
    if (score == null) {
      return INFO;
    }
    if (score >= healthyMin) {
      return HEALTHY;
    }
    if (score >= warningMin) {
      return WARNING;
    }
    return CRITICAL;
  }

  /** Component scores all use the 90/75 band. */
  public static String fromScore(Decimal score) {
    return fromScore(score, SCORE_HEALTHY, SCORE_WARNING);
  }

  /** The worst status in a list wins - used for every roll-up card. */
  public static String worst(List<String> statuses) {
    String result = null;
    for (String candidate : statuses) {
      if (candidate == null) {
        continue;
      }
      if (result == null || RANK.get(candidate) > RANK.get(result)) {
        result = candidate;
      }
    }
    return result == null ? HEALTHY : result;
  }

  public static String label(String status) {
    return LABEL.containsKey(status) ? LABEL.get(status) : LABEL.get(INFO);
  }

  /* ==========================================================================
   * Arithmetic helpers - every percentage on the page comes through here
   * ========================================================================== */

  /** current / maximum x 100, guarding division by zero. */
  public static Decimal percent(Decimal current, Decimal maximum) {
    if (current == null || maximum == null || maximum == 0) {
      return 0;
    }
    return (current / maximum) * 100;
  }

  /** Rounded whole-number percentage string, e.g. "68%". */
  public static String percentLabel(Decimal value) {
    if (value == null) {
      return '-';
    }
    return String.valueOf(value.setScale(0, System.RoundingMode.HALF_UP)) + '%';
  }

  /** Thousands-separated integer, e.g. "102,450". */
  public static String number(Long value) {
    if (value == null) {
      return '-';
    }
    String digits = String.valueOf(Math.abs(value));
    String grouped = '';
    Integer count = 0;
    for (Integer i = digits.length() - 1; i >= 0; i--) {
      grouped = digits.substring(i, i + 1) + grouped;
      count++;
      if (Math.mod(count, 3) == 0 && i > 0) {
        grouped = ',' + grouped;
      }
    }
    return (value < 0 ? '-' : '') + grouped;
  }
}
