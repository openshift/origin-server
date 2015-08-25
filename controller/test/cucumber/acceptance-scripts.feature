@node_extended
@node_extended3
Feature: Acceptance scripts for sanity checking infrastructure

  Scenario: Acceptance scripts usage
    Given an accepted node

  Scenario Outline:
    Then running <script> should yield <output> with a <exitcode> exitstatus
    And no stack traces should have occurred

  @not-origin
  @not-enterprise
  Scenarios: Acceptance script scenarios
    |     script                                   |   output   | exitcode |
    | /usr/sbin/oo-accept-systems |   PASS     |     0    |

  @not-online
  Scenarios: Acceptance script scenarios
    |     script        |   output   | exitcode |
    | oo-accept-systems |   PASS     |     0    |
