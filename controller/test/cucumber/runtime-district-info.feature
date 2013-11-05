@node
@node1
Feature: District Configuration
  Scenario: Write and update district file
    Given a new active district with first_uid 1000 and max_uid 6999
    Then the district info file should match the district
    And the file /etc/openshift/district.conf does not exist
    When the district is updated with first_uid 10000 and max_uid 15000
    Then the district info file should match the district
    Then remove the district info file
