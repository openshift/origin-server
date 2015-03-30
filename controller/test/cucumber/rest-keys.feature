@broker_api
@broker_api2
Feature: keys
  As an API client
  In order to do things with keys
  I want to List, Create, Retrieve, Update and Delete keys

  Scenario Outline: Create, List, Get, Update, Delete
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQDa/hAlFXyOr+8NIroKEJjqLkxOJD0qZLGXiMjIj4KulKt6H81OGZbnQP+sBfZtQ0aZA5IhQf5paznU8rSPz1yRcXUZv40mi/6yzpnI8pM2IJ7AHRrrXN/LfCrHInCfhJKzjh8aZwsaB/367diCfTundPsHcth2V70v7lTnrR1QJsKsFJFbsgdfiP6fw/+VN9kD37zJZQ9zLG4cy8BBfZKOqTg9wVgGEWOx6KBGDbX1UqnJZ8HFbmTgoUJbyLDSdAjnDGiM1IvyFat5Yw9nhNbT+mc/2e/4VfH0T3G9ff2dbVH37GDNZ5muB8HfzHhq3FT/VMmyfzVhWKxDmXG/E8IX"
    Then the response should be "201"
    And the response should be a "key" with attributes "name=api&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQDa/hAlFXyOr+8NIroKEJjqLkxOJD0qZLGXiMjIj4KulKt6H81OGZbnQP+sBfZtQ0aZA5IhQf5paznU8rSPz1yRcXUZv40mi/6yzpnI8pM2IJ7AHRrrXN/LfCrHInCfhJKzjh8aZwsaB/367diCfTundPsHcth2V70v7lTnrR1QJsKsFJFbsgdfiP6fw/+VN9kD37zJZQ9zLG4cy8BBfZKOqTg9wVgGEWOx6KBGDbX1UqnJZ8HFbmTgoUJbyLDSdAjnDGiM1IvyFat5Yw9nhNbT+mc/2e/4VfH0T3G9ff2dbVH37GDNZ5muB8HfzHhq3FT/VMmyfzVhWKxDmXG/E8IX"
    When I send a GET request to "/user/keys"
    Then the response should be "200"
    When I send a GET request to "/user/keys/api"
    Then the response should be "200"
    And the response should be a "key" with attributes "name=api&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQDa/hAlFXyOr+8NIroKEJjqLkxOJD0qZLGXiMjIj4KulKt6H81OGZbnQP+sBfZtQ0aZA5IhQf5paznU8rSPz1yRcXUZv40mi/6yzpnI8pM2IJ7AHRrrXN/LfCrHInCfhJKzjh8aZwsaB/367diCfTundPsHcth2V70v7lTnrR1QJsKsFJFbsgdfiP6fw/+VN9kD37zJZQ9zLG4cy8BBfZKOqTg9wVgGEWOx6KBGDbX1UqnJZ8HFbmTgoUJbyLDSdAjnDGiM1IvyFat5Yw9nhNbT+mc/2e/4VfH0T3G9ff2dbVH37GDNZ5muB8HfzHhq3FT/VMmyfzVhWKxDmXG/E8IX"
    When I send a PUT request to "/user/keys/api" with the following:"type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQCyCOjIXYAZjJ6nrzM9fUkY/pgYMI/N3N+1Cw9srzlPpJgclJmqga8lCz/LtmtM4GIXQUbqgan3DgVL8bxgFZPF7nOS4RRfu9Ggv5ZTIQ595q/pnxS2ShMpl8BFhO/mpqfCyOi1yf6/HtjLTLO9Jju/4lq4baCKjufd8ZnIWC0U+DK7/dBYcrKUpQFzl6isply1lg/rUhCGdXbqJlajIxwoY1qZP7KBc3WuoMPO7rVEblKqAfhMStuy2nIPzBhYQU43Y2UQ4THxUjgbAUizaWavqijkks7xZXREmsfoKURO4hHfg43gjL0jmBU7PSqVq8yzCR3OsW0YBKlnoNy5K/Yr"
    Then the response should be "200"
    And the response should be a "key" with attributes "name=api&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQCyCOjIXYAZjJ6nrzM9fUkY/pgYMI/N3N+1Cw9srzlPpJgclJmqga8lCz/LtmtM4GIXQUbqgan3DgVL8bxgFZPF7nOS4RRfu9Ggv5ZTIQ595q/pnxS2ShMpl8BFhO/mpqfCyOi1yf6/HtjLTLO9Jju/4lq4baCKjufd8ZnIWC0U+DK7/dBYcrKUpQFzl6isply1lg/rUhCGdXbqJlajIxwoY1qZP7KBc3WuoMPO7rVEblKqAfhMStuy2nIPzBhYQU43Y2UQ4THxUjgbAUizaWavqijkks7xZXREmsfoKURO4hHfg43gjL0jmBU7PSqVq8yzCR3OsW0YBKlnoNy5K/Yr"
    When I send a GET request to "/user/keys/blah"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=118"
    When I send a PUT request to "/user/keys/blah" with the following:"type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQCyCOjIXYAZjJ6nrzM9fUkY/pgYMI/N3N+1Cw9srzlPpJgclJmqga8lCz/LtmtM4GIXQUbqgan3DgVL8bxgFZPF7nOS4RRfu9Ggv5ZTIQ595q/pnxS2ShMpl8BFhO/mpqfCyOi1yf6/HtjLTLO9Jju/4lq4baCKjufd8ZnIWC0U+DK7/dBYcrKUpQFzl6isply1lg/rUhCGdXbqJlajIxwoY1qZP7KBc3WuoMPO7rVEblKqAfhMStuy2nIPzBhYQU43Y2UQ4THxUjgbAUizaWavqijkks7xZXREmsfoKURO4hHfg43gjL0jmBU7PSqVq8yzCR3OsW0YBKlnoNy5K/Yr"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=118"
    When I send a DELETE request to "/user/keys/api"
    Then the response should be "200"
    When I send a DELETE request to "/user/keys/api"
    Then the response should be "404"
    And the error message should have "severity=error&exit_code=118"

    Scenarios:
     | format |
     | JSON   |
     | XML    |

  Scenario Outline: Create key with with blank, missing and invalid content
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=XYZ123=567[dfhhfl]"
    Then the response should be "422"
    And the error message should have "field=content&severity=error&exit_code=108"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content="
    Then the response should be "422"
    And the error message should have "field=content&severity=error&exit_code=108"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa"
    Then the response should be "422"
    And the error message should have "field=content&severity=error&exit_code=108"

    Scenarios:
     | format |
     | JSON   |
     | XML    |

  Scenario Outline: Create key with with blank, missing, too long and invalid name
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=cucum?*ber&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQDa/hAlFXyOr+8NIroKEJjqLkxOJD0qZLGXiMjIj4KulKt6H81OGZbnQP+sBfZtQ0aZA5IhQf5paznU8rSPz1yRcXUZv40mi/6yzpnI8pM2IJ7AHRrrXN/LfCrHInCfhJKzjh8aZwsaB/367diCfTundPsHcth2V70v7lTnrR1QJsKsFJFbsgdfiP6fw/+VN9kD37zJZQ9zLG4cy8BBfZKOqTg9wVgGEWOx6KBGDbX1UqnJZ8HFbmTgoUJbyLDSdAjnDGiM1IvyFat5Yw9nhNbT+mc/2e/4VfH0T3G9ff2dbVH37GDNZ5muB8HfzHhq3FT/VMmyfzVhWKxDmXG/E8IX"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=117"
    When I send a POST request to "/user/keys" with the following:"name=&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQDa/hAlFXyOr+8NIroKEJjqLkxOJD0qZLGXiMjIj4KulKt6H81OGZbnQP+sBfZtQ0aZA5IhQf5paznU8rSPz1yRcXUZv40mi/6yzpnI8pM2IJ7AHRrrXN/LfCrHInCfhJKzjh8aZwsaB/367diCfTundPsHcth2V70v7lTnrR1QJsKsFJFbsgdfiP6fw/+VN9kD37zJZQ9zLG4cy8BBfZKOqTg9wVgGEWOx6KBGDbX1UqnJZ8HFbmTgoUJbyLDSdAjnDGiM1IvyFat5Yw9nhNbT+mc/2e/4VfH0T3G9ff2dbVH37GDNZ5muB8HfzHhq3FT/VMmyfzVhWKxDmXG/E8IX"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=117"
    When I send a POST request to "/user/keys" with the following:"type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQDa/hAlFXyOr+8NIroKEJjqLkxOJD0qZLGXiMjIj4KulKt6H81OGZbnQP+sBfZtQ0aZA5IhQf5paznU8rSPz1yRcXUZv40mi/6yzpnI8pM2IJ7AHRrrXN/LfCrHInCfhJKzjh8aZwsaB/367diCfTundPsHcth2V70v7lTnrR1QJsKsFJFbsgdfiP6fw/+VN9kD37zJZQ9zLG4cy8BBfZKOqTg9wVgGEWOx6KBGDbX1UqnJZ8HFbmTgoUJbyLDSdAjnDGiM1IvyFat5Yw9nhNbT+mc/2e/4VfH0T3G9ff2dbVH37GDNZ5muB8HfzHhq3FT/VMmyfzVhWKxDmXG/E8IX"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=117"
    When I send a POST request to "/user/keys" with the following:"name=cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQDa/hAlFXyOr+8NIroKEJjqLkxOJD0qZLGXiMjIj4KulKt6H81OGZbnQP+sBfZtQ0aZA5IhQf5paznU8rSPz1yRcXUZv40mi/6yzpnI8pM2IJ7AHRrrXN/LfCrHInCfhJKzjh8aZwsaB/367diCfTundPsHcth2V70v7lTnrR1QJsKsFJFbsgdfiP6fw/+VN9kD37zJZQ9zLG4cy8BBfZKOqTg9wVgGEWOx6KBGDbX1UqnJZ8HFbmTgoUJbyLDSdAjnDGiM1IvyFat5Yw9nhNbT+mc/2e/4VfH0T3G9ff2dbVH37GDNZ5muB8HfzHhq3FT/VMmyfzVhWKxDmXG/E8IX"
    Then the response should be "422"
    And the error message should have "field=name&severity=error&exit_code=117"

    Scenarios:
     | format |
     | JSON   |
     | XML    |

  Scenario Outline: Create key with blank, missing and invalid type
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-xyz&content=XYZ123567"
    Then the response should be "422"
    And the error message should have "field=type&severity=error&exit_code=116"
    When I send a POST request to "/user/keys" with the following:"name=api&type=&content=XYZ123567"
    Then the response should be "422"
    And the error message should have "field=type&severity=error&exit_code=116"
    When I send a POST request to "/user/keys" with the following:"name=api&content=XYZ123567"
    Then the response should be "422"
    And the error message should have "field=type&severity=error&exit_code=116"

    Scenarios:
     | format |
     | JSON   |
     | XML    |

  Scenario Outline: Update key with with blank, missing and invalid content
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQDa/hAlFXyOr+8NIroKEJjqLkxOJD0qZLGXiMjIj4KulKt6H81OGZbnQP+sBfZtQ0aZA5IhQf5paznU8rSPz1yRcXUZv40mi/6yzpnI8pM2IJ7AHRrrXN/LfCrHInCfhJKzjh8aZwsaB/367diCfTundPsHcth2V70v7lTnrR1QJsKsFJFbsgdfiP6fw/+VN9kD37zJZQ9zLG4cy8BBfZKOqTg9wVgGEWOx6KBGDbX1UqnJZ8HFbmTgoUJbyLDSdAjnDGiM1IvyFat5Yw9nhNbT+mc/2e/4VfH0T3G9ff2dbVH37GDNZ5muB8HfzHhq3FT/VMmyfzVhWKxDmXG/E8IX"
    Then the response should be "201"
    When I send a PUT request to "/user/keys/api" with the following:"type=ssh-rsa&content="
    Then the response should be "422"
    And the error message should have "field=content&severity=error&exit_code=108"
    When I send a PUT request to "/user/keys/api" with the following:"type=ssh-rsa"
    Then the response should be "422"
    And the error message should have "field=content&severity=error&exit_code=108"
    When I send a PUT request to "/user/keys/api" with the following:"type=ssh-rsa&content=ABC8??#@@90"
    Then the response should be "422"
    And the error message should have "field=content&severity=error&exit_code=108"
    When I send a GET request to "/user/keys/api"
    Then the response should be "200"
    And the response should be a "key" with attributes "name=api&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQDa/hAlFXyOr+8NIroKEJjqLkxOJD0qZLGXiMjIj4KulKt6H81OGZbnQP+sBfZtQ0aZA5IhQf5paznU8rSPz1yRcXUZv40mi/6yzpnI8pM2IJ7AHRrrXN/LfCrHInCfhJKzjh8aZwsaB/367diCfTundPsHcth2V70v7lTnrR1QJsKsFJFbsgdfiP6fw/+VN9kD37zJZQ9zLG4cy8BBfZKOqTg9wVgGEWOx6KBGDbX1UqnJZ8HFbmTgoUJbyLDSdAjnDGiM1IvyFat5Yw9nhNbT+mc/2e/4VfH0T3G9ff2dbVH37GDNZ5muB8HfzHhq3FT/VMmyfzVhWKxDmXG/E8IX"

    Scenarios:
     | format |
     | JSON   |
     | XML    |

  Scenario Outline: Update key with blank, missing and invalid type
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQDa/hAlFXyOr+8NIroKEJjqLkxOJD0qZLGXiMjIj4KulKt6H81OGZbnQP+sBfZtQ0aZA5IhQf5paznU8rSPz1yRcXUZv40mi/6yzpnI8pM2IJ7AHRrrXN/LfCrHInCfhJKzjh8aZwsaB/367diCfTundPsHcth2V70v7lTnrR1QJsKsFJFbsgdfiP6fw/+VN9kD37zJZQ9zLG4cy8BBfZKOqTg9wVgGEWOx6KBGDbX1UqnJZ8HFbmTgoUJbyLDSdAjnDGiM1IvyFat5Yw9nhNbT+mc/2e/4VfH0T3G9ff2dbVH37GDNZ5muB8HfzHhq3FT/VMmyfzVhWKxDmXG/E8IX"
    Then the response should be "201"
    When I send a PUT request to "/user/keys/api" with the following:"type=&content=ABC890"
    Then the response should be "422"
    And the error message should have "field=type&severity=error&exit_code=116"
    When I send a PUT request to "/user/keys/api" with the following:"&content=ABC890"
    Then the response should be "422"
    And the error message should have "field=type&severity=error&exit_code=116"
    When I send a PUT request to "/user/keys/api" with the following:"type=ssh-abc&content=ABC890"
    Then the response should be "422"
    And the error message should have "field=type&severity=error&exit_code=116"
    When I send a GET request to "/user/keys/api"
    Then the response should be "200"
    And the response should be a "key" with attributes "name=api&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQDa/hAlFXyOr+8NIroKEJjqLkxOJD0qZLGXiMjIj4KulKt6H81OGZbnQP+sBfZtQ0aZA5IhQf5paznU8rSPz1yRcXUZv40mi/6yzpnI8pM2IJ7AHRrrXN/LfCrHInCfhJKzjh8aZwsaB/367diCfTundPsHcth2V70v7lTnrR1QJsKsFJFbsgdfiP6fw/+VN9kD37zJZQ9zLG4cy8BBfZKOqTg9wVgGEWOx6KBGDbX1UqnJZ8HFbmTgoUJbyLDSdAjnDGiM1IvyFat5Yw9nhNbT+mc/2e/4VfH0T3G9ff2dbVH37GDNZ5muB8HfzHhq3FT/VMmyfzVhWKxDmXG/E8IX"

    Scenarios:
     | format |
     | JSON   |
     | XML    |

  Scenario Outline: Create duplicate key
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQDa/hAlFXyOr+8NIroKEJjqLkxOJD0qZLGXiMjIj4KulKt6H81OGZbnQP+sBfZtQ0aZA5IhQf5paznU8rSPz1yRcXUZv40mi/6yzpnI8pM2IJ7AHRrrXN/LfCrHInCfhJKzjh8aZwsaB/367diCfTundPsHcth2V70v7lTnrR1QJsKsFJFbsgdfiP6fw/+VN9kD37zJZQ9zLG4cy8BBfZKOqTg9wVgGEWOx6KBGDbX1UqnJZ8HFbmTgoUJbyLDSdAjnDGiM1IvyFat5Yw9nhNbT+mc/2e/4VfH0T3G9ff2dbVH37GDNZ5muB8HfzHhq3FT/VMmyfzVhWKxDmXG/E8IX"
    Then the response should be "201"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAAAgQCwSyig/Pr/S/+OHgnl4LjgckwnUTi48yAz/zmugNxyBVs1CUNXaP8tQ0njqgjqjZDFbdkvGbsTDhJfWqOkQ5vD66jgkpojHmEsRX+KtsrKl2vDrRCXzPvxQ1tfE9wxrcWatQqUpESK0ZBg7C3ssg+Djk44OeDPWYyMh2hv6jBVvQ=="
    Then the response should be "409"
    When I send a POST request to "/user/keys" with the following:"name=apiX&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQDa/hAlFXyOr+8NIroKEJjqLkxOJD0qZLGXiMjIj4KulKt6H81OGZbnQP+sBfZtQ0aZA5IhQf5paznU8rSPz1yRcXUZv40mi/6yzpnI8pM2IJ7AHRrrXN/LfCrHInCfhJKzjh8aZwsaB/367diCfTundPsHcth2V70v7lTnrR1QJsKsFJFbsgdfiP6fw/+VN9kD37zJZQ9zLG4cy8BBfZKOqTg9wVgGEWOx6KBGDbX1UqnJZ8HFbmTgoUJbyLDSdAjnDGiM1IvyFat5Yw9nhNbT+mc/2e/4VfH0T3G9ff2dbVH37GDNZ5muB8HfzHhq3FT/VMmyfzVhWKxDmXG/E8IX"
    Then the response should be "409"

    Scenarios:
     | format |
     | JSON   |
     | XML    |

   Scenario Outline: Create keys of varying lengths
    Given a new user
    And I accept "<format>"
    When I send a POST request to "/user/keys" with the following:"name=api&type=ssh-rsa&content=AAAAB3NzaC1yc2EAAAADAQABAAABAQDa/hAlFXyOr+8NIroKEJjqLkxOJD0qZLGXiMjIj4KulKt6H81OGZbnQP+sBfZtQ0aZA5IhQf5paznU8rSPz1yRcXUZv40mi/6yzpnI8pM2IJ7AHRrrXN/LfCrHInCfhJKzjh8aZwsaB/367diCfTundPsHcth2V70v7lTnrR1QJsKsFJFbsgdfiP6fw/+VN9kD37zJZQ9zLG4cy8BBfZKOqTg9wVgGEWOx6KBGDbX1UqnJZ8HFbmTgoUJbyLDSdAjnDGiM1IvyFat5Yw9nhNbT+mc/2e/4VfH0T3G9ff2dbVH37GDNZ5muB8HfzHhq3FT/VMmyfzVhWKxDmXG/E8IX"
    Then the response should be "201"
    When I send a POST request to "/user/keys" with the following:"name=dss1024&type=ssh-dss&content=AAAAB3NzaC1kc3MAAACBAMKbO9DyBwLdSUkm/gE0KS8pL0EWSTe0B6IzhghbOA2oQyz/g/2LvehUZfempmcIhEDIVburLlWEKusuk8B/bngcnMWx3HmtIVopbuSbFrZE7PAiE4iRfb5VKiQUpWtGiTGDTMq9JJWg1TA0QU7HdKwRVTWzCcRzjE3b/RvoHWQzAAAAFQCaEQ+SG4xlUs0/KV66se7qZRZKYwAAAIAPhZJ+dtQblwOGk7a4TzcjWZhXjT6Sa2vFgXFnbjjVOTUvog8SIGkrWxtgNeF6YgrgZYHhSJEariLdh7ZiQyKA4+9J0h1NYdmfrNCM+6ZohP2uMum7I7JTowjiET0iZrli1JciwyO8hz+YMLrgeO9AfOnXQwMUwiDcZ44dfIxlLQAAAIEAugXzYScsDJs1S9OFVQvY0OiLcQE/sBoDuud1LxDrdN9Ui45j1USOgxZTUMRWnBlH38Vy7cPOrPBSUM7WvjUnlei1767IRTDld4wNstICtzbUsRX7TvpKv6uyO4NzCYv2EH4ap74kpHxKh6t7pXsRo3B90Aex8NGwDAHO6iEq49Y="
    Then the response should be "201"
    And the response should be a "key" with attributes "name=dss1024&type=ssh-dss&content=AAAAB3NzaC1kc3MAAACBAMKbO9DyBwLdSUkm/gE0KS8pL0EWSTe0B6IzhghbOA2oQyz/g/2LvehUZfempmcIhEDIVburLlWEKusuk8B/bngcnMWx3HmtIVopbuSbFrZE7PAiE4iRfb5VKiQUpWtGiTGDTMq9JJWg1TA0QU7HdKwRVTWzCcRzjE3b/RvoHWQzAAAAFQCaEQ+SG4xlUs0/KV66se7qZRZKYwAAAIAPhZJ+dtQblwOGk7a4TzcjWZhXjT6Sa2vFgXFnbjjVOTUvog8SIGkrWxtgNeF6YgrgZYHhSJEariLdh7ZiQyKA4+9J0h1NYdmfrNCM+6ZohP2uMum7I7JTowjiET0iZrli1JciwyO8hz+YMLrgeO9AfOnXQwMUwiDcZ44dfIxlLQAAAIEAugXzYScsDJs1S9OFVQvY0OiLcQE/sBoDuud1LxDrdN9Ui45j1USOgxZTUMRWnBlH38Vy7cPOrPBSUM7WvjUnlei1767IRTDld4wNstICtzbUsRX7TvpKv6uyO4NzCYv2EH4ap74kpHxKh6t7pXsRo3B90Aex8NGwDAHO6iEq49Y="

    Scenarios:
     | format |
     | JSON   |
     | XML    |


