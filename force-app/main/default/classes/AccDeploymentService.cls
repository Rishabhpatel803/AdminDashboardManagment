/**
 * Section 8 - Deployment & DevOps.
 *
 * Deployment history (DeployRequest / DeployResult), change sets and pipeline
 * status are Metadata API concepts with no SOQL-queryable object, so nothing
 * in this section can be read from Apex. It is reported as unavailable in
 * full rather than seeded with any placeholder numbers, and is excluded from
 * the weighted instance health score.
 */
public with sharing class AccDeploymentService {
  private static final String REASON = 'Data Unavailable: deployment history, change sets and pipeline status are Metadata API concepts with no object exposed to Apex SOQL.';

  public static AccModel.DeploymentSection build() {
    AccModel.DeploymentSection section = new AccModel.DeploymentSection();
    section.unavailable = true;
    section.unavailableReason = REASON;
    section.status = AccStatus.INFO;
    section.successRateLabel = 'N/A';

    section.footer.add(unavailableTile('f1', 'Change Sets'));
    section.footer.add(unavailableTile('f2', 'DevOps Pipeline'));
    section.footer.add(unavailableTile('f3', 'Last Production Release'));

    return section;
  }

  private static AccModel.Tile unavailableTile(String id, String label) {
    AccModel.Tile tile = new AccModel.Tile(id, label, 'N/A', AccStatus.INFO);
    tile.unavailable = true;
    tile.tooltip = REASON;
    return tile;
  }
}
