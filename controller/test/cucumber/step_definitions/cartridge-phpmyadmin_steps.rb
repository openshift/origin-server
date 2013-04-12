Given /^a php-([\d\.]+) application, verify addition and removal of phpmyadmin-([\d\.]+)$/ do |php_version, phpmyadmin_version|
  steps %Q{    
    Given a new php-#{php_version} type application
        
    When I embed a mysql-5.1 cartridge into the application
    And I embed a phpmyadmin-#{phpmyadmin_version} cartridge into the application
    Then the http proxy /phpmyadmin will exist
    And 4 processes named httpd will be running
    And the embedded phpmyadmin-#{phpmyadmin_version} cartridge directory will exist
    And the embedded phpmyadmin-#{phpmyadmin_version} cartridge log files will exist
    
    When I stop the phpmyadmin-#{phpmyadmin_version} cartridge
    Then 2 processes named httpd will be running
    And the web console for the phpmyadmin-#{phpmyadmin_version} cartridge is not accessible
    
    When I start the phpmyadmin-#{phpmyadmin_version} cartridge
    Then 4 processes named httpd will be running
    And the web console for the phpmyadmin-#{phpmyadmin_version} cartridge is accessible
        
    When I restart the phpmyadmin-#{phpmyadmin_version} cartridge
    Then 4 processes named httpd will be running
    And the web console for the phpmyadmin-#{phpmyadmin_version} cartridge is accessible
    
    When I destroy the application
    Then 0 processes named httpd will be running
    And the http proxy /phpmyadmin will not exist
    And the embedded phpmyadmin-#{phpmyadmin_version} cartridge directory will not exist
    And the embedded phpmyadmin-#{phpmyadmin_version} cartridge log files will not exist
  }
end

Given /^a mock application, verify addition and removal of v2 phpmyadmin-([\d\.]+)$/ do |phpmyadmin_version|
  steps %Q{
    Given a v2 default node
    Given a new mock-0.1 type application
    
    When I embed a mysql-5.1 cartridge into the application
    And I embed a phpmyadmin-#{phpmyadmin_version} cartridge into the application
    Then a httpd process will be running
    And the phpmyadmin-#{phpmyadmin_version} cartridge instance directory will exist
    
    When I stop the phpmyadmin-#{phpmyadmin_version} cartridge
    Then a httpd process will not be running
    
    When I start the phpmyadmin-#{phpmyadmin_version} cartridge
    Then a httpd process will be running
  
    When I restart the phpmyadmin-#{phpmyadmin_version} cartridge
    Then a httpd process will be running
    
    When I destroy the application
    Then a httpd process will not be running
  }
end
