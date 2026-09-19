/**
 * Section 1 - Overall Instance Health.
 *
 * Weighted roll-up per the specification's table:
 *   Security 20%, Automation 15%, Integrations 15%, API & Limits 15%,
 *   Storage 10%, Deployments 10%, Apex & Code Health 10%.
 *
 * NOTE: those weights are labelled "Total 100%" in the specification but sum
 * to 95%. The score below is normalised by the actual weight total, which is
 * the mathematically correct treatment of a weighted average - summing the
 * raw products instead would silently scale every score down by 5%.
 *
 * A component whose data is unavailable is excluded from both the weighted
 * sum and the weight total, rather than being treated as a zero score, so a
 * single unreachable metric does not drag down the whole instance rating.
 */
public with sharing class AccHealthService {
  public static AccModel.HealthSection build(AccModel.Payload payload) {
    AccModel.HealthSection health = new AccModel.HealthSection();

    List<Object> components = new List<Object>{
      new List<Object>{ 'security', 'Security', 0.20, payload.security },
      new List<Object>{ 'automation', 'Automation', 0.15, payload.automation },
      new List<Object>{
        'integrations',
        'Integrations',
        0.15,
        payload.integrations
      },
      new List<Object>{ 'limits', 'API & Limits', 0.15, payload.limits },
      new List<Object>{ 'storage', 'Storage', 0.10, payload.dataOverview },
      new List<Object>{
        'deployments',
        'Deployments',
        0.10,
        payload.deployments
      },
      new List<Object>{ 'code', 'Apex & Code Health', 0.10, payload.code }
    };

    Decimal weightedSum = 0;
    Decimal weightTotal = 0;

    for (Object entry : components) {
      Object[] row = (Object[]) entry;
      String id = (String) row[0];
      String name = (String) row[1];
      Decimal weight = (Decimal) row[2];
      Boolean unavailable = isUnavailable(row[3]);
      Decimal score = unavailable ? null : sectionScore(row[3]);

      AccModel.HealthComponent component = new AccModel.HealthComponent();
      component.id = id;
      component.name = name;
      component.weight = String.valueOf((weight * 100).intValue()) + '%';
      component.counted = !unavailable && score != null;

      if (component.counted) {
        component.score = score.intValue();
        component.status = AccStatus.fromScore(score);
        weightedSum += score * weight;
        weightTotal += weight;
      } else {
        component.score = null;
        component.status = AccStatus.INFO;
      }
      health.components.add(component);
    }

    if (weightTotal == 0) {
      health.score = null;
      health.scoreLabel = 'N/A';
      health.status = AccStatus.INFO;
      health.statusLabel = 'Data Unavailable';
      health.tooltip = 'No component with a computable score is available in this org.';
      return health;
    }

    Decimal score = weightedSum / weightTotal;
    String status = AccStatus.fromScore(score);

    /*
     * Critical Override Rule: a critical security incident (Modify/View All
     * Data misuse we can actually detect) or a confirmed critical component
     * forces the overall status to Critical regardless of the weighted score.
     * Integration and Salesforce service availability cannot be confirmed
     * from Apex, so they cannot trigger the override here.
     */
    if (
      payload.security != null &&
      payload.security.status == AccStatus.CRITICAL
    ) {
      status = AccStatus.CRITICAL;
    }

    health.score = score;
    health.scoreLabel = AccStatus.percentLabel(score);
    health.status = status;
    health.statusLabel = AccStatus.label(status);

    List<String> breakdown = new List<String>();
    for (AccModel.HealthComponent component : health.components) {
      if (component.counted) {
        breakdown.add(
          component.name + ' ' + component.score + ' x ' + component.weight
        );
      } else {
        breakdown.add(component.name + ' unavailable (excluded)');
      }
    }
    health.tooltip =
      'Weighted instance health ' +
      score.setScale(1) +
      '/100 across ' +
      weightTotal.setScale(2) +
      ' of weight (' +
      String.join(breakdown, ', ') +
      ').';

    return health;
  }

  /* ==========================================================================
   * Section score / unavailability lookups
   *
   * Every section DTO repeats `unavailable` and `score` rather than sharing a
   * base type (Apex does not reliably serialise inherited @AuraEnabled fields
   * to LWC - see AccModel), so these helpers switch on concrete type instead
   * of a common interface.
   * ========================================================================== */

  private static Boolean isUnavailable(Object section) {
    if (section instanceof AccModel.SecuritySection) {
      return ((AccModel.SecuritySection) section).unavailable;
    }
    if (section instanceof AccModel.AutomationSection) {
      return ((AccModel.AutomationSection) section).unavailable;
    }
    if (section instanceof AccModel.IntegrationSection) {
      return ((AccModel.IntegrationSection) section).unavailable;
    }
    if (section instanceof AccModel.LimitSection) {
      return ((AccModel.LimitSection) section).unavailable;
    }
    if (section instanceof AccModel.DeploymentSection) {
      return ((AccModel.DeploymentSection) section).unavailable;
    }
    if (section instanceof AccModel.CodeSection) {
      return ((AccModel.CodeSection) section).unavailable;
    }
    if (section instanceof AccModel.DataSection) {
      return ((AccModel.DataSection) section).unavailable;
    }
    return true;
  }

  private static Decimal sectionScore(Object section) {
    if (section instanceof AccModel.SecuritySection) {
      return ((AccModel.SecuritySection) section).score;
    }
    if (section instanceof AccModel.AutomationSection) {
      return ((AccModel.AutomationSection) section).score;
    }
    if (section instanceof AccModel.IntegrationSection) {
      return ((AccModel.IntegrationSection) section).score;
    }
    if (section instanceof AccModel.LimitSection) {
      return ((AccModel.LimitSection) section).score;
    }
    if (section instanceof AccModel.DeploymentSection) {
      return ((AccModel.DeploymentSection) section).score;
    }
    if (section instanceof AccModel.CodeSection) {
      return ((AccModel.CodeSection) section).score;
    }
    if (section instanceof AccModel.DataSection) {
      return ((AccModel.DataSection) section).score;
    }
    return null;
  }
}
