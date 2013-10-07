@runtime
@runtime3
Feature: V2 Platform Endpoint tests

  Scenario: SSL to Gear is specified in the cartridge's manifest.yml
    Given a new client created scalable mock-0.3 application
    Then the Apache nodes DB file will contain SSL_TO_GEAR for the ssl_to_gear endpoint
    And the haproxy.cfg file will be configured to proxy SSL to the backend gear

    When I send an http request to the app
    Then It will return location https://testssl-testuser.dev.rhcloud.com

    When I send an https request to the app
    Then It will return content <html>\n  <body>\n    Goodbye, cruel world!\n  </body>\n</html>\n\n


  Scenario: SNI Proxy is requested by the cartridge's manifest.yml
    Given a new client created mock-0.4 application
    When I send an https request to the app on port 2303
    Then It will return content <html>\n  <body>\n    Goodbye, cruel world!\n  </body>\n</html>\n\n
