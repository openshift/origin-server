REST API Version Compatibility:
-------------------------------
- api*.rb files are helper scripts for rest_api_test.rb unit test.
- These tests will ensure supported versions of REST APIs are working correctly.
  For every supported version of REST api, it validates consistency of these cases:
   * Request/Response version
   * Request parameters
   * Request default values
   * Response status
   * Response type
   * Response parameters
   * Response links

NOTE: For supported REST api version 'X', api_model_v<X>, api_v<X> has expected request/response format. 
      If the rest api unit test fails in any of these files, we have to fix the broker code and *NOT* the unit tests.

- Follow these steps to add unit tests for *New* version of REST api
  a) copy api_model_v<#prev-version>.rb to api_model_v<#new-version>.rb
  b) copy api_v<#prev-version>.rb to api_v<#new-version>.rb
  c) Modify api_model_v<#new-version>.rb, api_v<#new-version>.rb that matches current broker code
  d) Add "require 'helpers/rest/api_v<#new-version>'" in api.rb
  e) Add new entry REST_CALLS_V<#new-version> to REST_CALLS array in api.rb
