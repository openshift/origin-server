@cartridge_fuse
@xpaas
@fuse

Feature: Cartridge Lifecycle Fuse Verification Tests
  Scenario Outline: Application Creation
    Given the libra client tools
    #When 1 <cart_name> applications are created
    When I create a fuse app
    Given an existing <cart_name> application
    Then the application should be accessible with path /hawtio/index.html

    #When the application is restarted
    #Then the application should be accessible with path /hawtio/index.html

    When a container named cbr is created using the quickstarts-beginner-camel.cbr profile
    Then 2 containers should exist
    
    Given an existing application named cbr
    Then 1 camel route should exist on app cbr
    When input files are copied from \$OPENSHIFT_FUSE_DIR/container/quickstarts/beginner/camel-cbr/src/main/fabric8/data/* to  \$OPENSHIFT_FUSE_DIR/container/work/cbr/input
    Then the app directory \$OPENSHIFT_FUSE_DIR/container/work/cbr/output should contain others/order1.xml uk/order2.xml uk/order4.xml us/order3.xml us/order5.xml
  
# destroy the cbr app
    When the application is destroyed
    Then the application should not be accessible

#  Scenario: Application Destroying
#    Given an existing <cart_name> application
    Given an existing <cart_name> application
    When the application is destroyed
    Then the application should not be accessible with path /hawtio/index.html

    Scenarios: Version scenarios
      | cart_name    |
      | fuse |
