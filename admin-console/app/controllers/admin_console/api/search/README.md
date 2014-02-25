OpenShift Origin Admin Console Search API
=========================================

The admin console search api provides querying capabilities for applications, domains, users, districts and usage records.

* Based at the path /admin-console/api/v1/search/
* Any parameters with {key}\_regex can not be specified when the param {key} is included and vice versa, e.g. you can't pass name and name\_regex, if this is violated a 422 will be returned
* Queries limited to 100 results by default, if there are additional results the response will have "more: true"
* An optional __limit__ parameter will override the default limit, allowing you to return more results
* You can specify multiple keys to query off of, e.g. for apps you could include both name and namespace
* You must specify at least one valid key to query from, the request will be rejected otherwise with a 422  (does not apply to districts)
* All queries read from secondary monogdb nodes if any are available, so eventual consistency applies


Applications
------------
{base_search_path}/applications.json

Parameters:
* gear_uuid
* domain_id
* name
* name_regex 
* namespace
* namespace_regex
* id

Domains
-------
{base_search_path}/domains.json

Parameters:
* id
* owner_id
* namespace
* namespace_regex

Users
-----
{base_search_path}/users.json

Parameters:
* id
* login
* login_regex
* plan_id
* usage_account_id

Districts
---------
{base_search_path}/districts.json

Parameters:
* id
* name
* name_regex

Usage Records
-------------
{base_search_path}/usages.json

Parameters:
* user_id
* gear_id
* app_name
* app_name_regex