ENV["TEST_NAME"] = "system_alias_test"
require 'test_helper'
require 'openshift-origin-controller'

class AliasTest < ActionDispatch::IntegrationTest

  DOMAIN_COLLECTION_URL = "/broker/rest/domains"
  APP_COLLECTION_URL_FORMAT = "/broker/rest/domains/%s/applications"
  APP_URL_FORMAT = "/broker/rest/domains/%s/applications/%s"
  APP_ALIAS_COLLECTION_URL_FORMAT = "/broker/rest/domains/%s/applications/%s/aliases"
  APP_ALIAS_URL_FORMAT = "/broker/rest/domains/%s/applications/%s/aliases/%s"

  def setup
    @random = rand(1000000000)
    @login = "user#{@random}"
    @user = CloudUser.new(login: @login)
    @user.save
    Lock.create_lock(@user)
    @headers = {}
    @headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{@login}:password")
    @headers["HTTP_ACCEPT"] = "application/json"

    ssl_certificate_data

    https!
  end

  def teardown
    # delete the domain
    request_via_redirect(:delete, DOMAIN_COLLECTION_URL + "/ns#{@random}", {:force => true}, @headers)
  end

  test "create alias for user without capability" do

    @ns = "ns#{@random}"
    @app = "app#{@random}"
    @as = "as.#{@random}"

    #create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:name => @ns}, @headers)
    assert_response :created

    # create an application under the user's domain
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [@ns], {:name => @app, :cartridge => "php-5.3"}, @headers)
    assert_response :created

    #create alias with certificate
    request_via_redirect(:post, APP_ALIAS_COLLECTION_URL_FORMAT % [@ns, @app], {:id => @as, :ssl_certificate => @ssl_certificate, :private_key => @private_key, :pass_phrase => @pass_phrase}, @headers)
    assert_response :forbidden
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 175)

    #create alias with no certificate
    request_via_redirect(:post, APP_ALIAS_COLLECTION_URL_FORMAT % [@ns, @app], {:id => @as}, @headers)
    assert_response :created
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["id"], @as)
    assert_equal(body["data"]["has_private_ssl_certificate"], false)

    #change certificate to alias
    request_via_redirect(:put, APP_ALIAS_URL_FORMAT % [@ns, @app, @as], {:ssl_certificate => @ssl_certificate, :private_key => @private_key, :pass_phrase => @pass_phrase}, @headers)
    assert_response :forbidden
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 175)

  end

  #In the interest of time instead of testing index, show, create, update and destroy individually
  # we have lumped them together
  test "alias lifecycle" do
    @ns = "ns#{@random}"
    @app = "app#{@random}"
    @as = "as#{@random}.foo.com"

    @user.capabilities["private_ssl_certificates"] = true
    @user.save

    #create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:name => @ns}, @headers)
    assert_response :created

    # create an application under the user's domain
    request_via_redirect(:post, APP_COLLECTION_URL_FORMAT % [@ns], {:name => @app, :cartridge => "php-5.3"}, @headers)
    assert_response :created

    # query alias list
    request_via_redirect(:get, APP_ALIAS_COLLECTION_URL_FORMAT % [@ns, @app], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"].length, 0)

    # query non-existent alias
    request_via_redirect(:get, APP_ALIAS_URL_FORMAT % [@ns, @app, @as], {}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 173)

    #try to create alias with bad inputs
    request_via_redirect(:post, APP_ALIAS_COLLECTION_URL_FORMAT % [@ns, @app], {:id => "@XYZ%^&!"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 105)

    request_via_redirect(:post, APP_ALIAS_COLLECTION_URL_FORMAT % [@ns, @app], {:id => ""}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 105)

    #try adding certificate without private key
    request_via_redirect(:post, APP_ALIAS_COLLECTION_URL_FORMAT % [@ns, @app], {:id => @as, :ssl_certificate => @ssl_certificate}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 172)
    assert_equal(body["messages"][0]["field"], "private_key")

    #try adding certificate with bad private key
    request_via_redirect(:post, APP_ALIAS_COLLECTION_URL_FORMAT % [@ns, @app], {:id => @as, :ssl_certificate => @ssl_certificate, :private_key => "ABCD"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 172)
    assert_equal(body["messages"][0]["field"], "private_key")

    #try adding certificate with wrong private key
    request_via_redirect(:post, APP_ALIAS_COLLECTION_URL_FORMAT % [@ns, @app], {:id => @as, :ssl_certificate => @ssl_certificate, :private_key => @wrong_private_key, :pass_phrase => @pass_phrase}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 172)
    assert_equal(body["messages"][0]["field"], "private_key")

    #try adding certificate with wrong certificate
    request_via_redirect(:post, APP_ALIAS_COLLECTION_URL_FORMAT % [@ns, @app], {:id => @as, :ssl_certificate => "ABCDEF", :private_key => @private_key, :pass_phrase => @pass_phrase}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 174)
    assert_equal(body["messages"][0]["field"], "ssl_certificate")

    #create alias with no certificate
    request_via_redirect(:post, APP_ALIAS_COLLECTION_URL_FORMAT % [@ns, @app], {:id => @as}, @headers)
    assert_response :created
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["id"], @as)
    assert_equal(body["data"]["has_private_ssl_certificate"], false)

    #get created alias
    request_via_redirect(:get, APP_ALIAS_URL_FORMAT % [@ns, @app, @as], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["id"], @as)
    assert_equal(body["data"]["has_private_ssl_certificate"], false)

    #add certificate to alias
    request_via_redirect(:put, APP_ALIAS_URL_FORMAT % [@ns, @app, @as], {:ssl_certificate => @ssl_certificate, :private_key => @private_key, :pass_phrase => @pass_phrase}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["id"], @as)
    assert_equal(body["data"]["has_private_ssl_certificate"], true)

    #delete alias
    request_via_redirect(:delete, APP_ALIAS_URL_FORMAT % [@ns, @app, @as], {}, @headers)
    assert_response :ok

    #create alias with certificate
    request_via_redirect(:post, APP_ALIAS_COLLECTION_URL_FORMAT % [@ns, @app], {:id => @as, :ssl_certificate => @ssl_certificate, :private_key => @private_key, :pass_phrase => @pass_phrase}, @headers)
    assert_response :created
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["id"], @as)
    assert_equal(body["data"]["has_private_ssl_certificate"], true)

    request_via_redirect(:get, APP_ALIAS_URL_FORMAT % [@ns, @app, @as], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["id"], @as)
    assert_equal(body["data"]["has_private_ssl_certificate"], true)

    #change certificate to alias
    request_via_redirect(:put, APP_ALIAS_URL_FORMAT % [@ns, @app, @as], {:ssl_certificate => @ssl_certificate, :private_key => @private_key, :pass_phrase => @pass_phrase}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)

    assert_equal(body["data"]["id"], @as)
    assert_equal(body["data"]["has_private_ssl_certificate"], true)

    #remove certificate to alias
    request_via_redirect(:put, APP_ALIAS_URL_FORMAT % [@ns, @app, @as], {}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)

    assert_equal(body["data"]["id"], @as)
    assert_equal(body["data"]["has_private_ssl_certificate"], false)

    #try to create an existing alias
    request_via_redirect(:post, APP_ALIAS_COLLECTION_URL_FORMAT % [@ns, @app], {:id => @as}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 140)

    #delete alias
    request_via_redirect(:delete, APP_ALIAS_URL_FORMAT % [@ns, @app, @as], {}, @headers)
    assert_response :ok

    #try to update a non-existent alias
    request_via_redirect(:put, APP_ALIAS_URL_FORMAT % [@ns, @app, @as], {:ssl_certificate => @ssl_certificate, :private_key => @private_key, :pass_phrase => @pass_phrase}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 173)

    #try to delete a non-existent alias
    request_via_redirect(:delete, APP_ALIAS_URL_FORMAT % [@ns, @app, @as], {}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 173)

  end

  def ssl_certificate_data

    @ssl_certificate = "-----BEGIN CERTIFICATE-----
MIIDoDCCAogCCQDzF8AJCHnrbjANBgkqhkiG9w0BAQUFADCBkTELMAkGA1UEBhMC
VVMxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlTdW5ueXZhbGUxDzANBgNVBAoMBnJl
ZGhhdDESMBAGA1UECwwJb3BlbnNoaWZ0MRIwEAYDVQQDDAlvcGVuc2hpZnQxKDAm
BgkqhkiG9w0BCQEWGWluZm9Ab3BlbnNoaWZ0LnJlZGhhdC5jb20wHhcNMTMwMjE5
MjExMTQ4WhcNMTQwMjE5MjExMTQ4WjCBkTELMAkGA1UEBhMCVVMxCzAJBgNVBAgM
AkNBMRIwEAYDVQQHDAlTdW5ueXZhbGUxDzANBgNVBAoMBnJlZGhhdDESMBAGA1UE
CwwJb3BlbnNoaWZ0MRIwEAYDVQQDDAlvcGVuc2hpZnQxKDAmBgkqhkiG9w0BCQEW
GWluZm9Ab3BlbnNoaWZ0LnJlZGhhdC5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IB
DwAwggEKAoIBAQDAEbH4MCi3iIDP1HS+/Xwu8SjdSc5WJX6htV7hJpmFZ8HohV/8
ba0v6aM9IJIIt+sIe2J62t/9G3leOdIHBxeACN4fV2l/iA/fvxvlnFKeD7sHm9Oc
Yj1H6YYJ57sIOf/oLDpJl6l3Rw8VC3+3W0/lzlVpA8qt7fpkiW7XQJCPplUSrdVC
3okQ2T5NAod5+wVIOqELgE5bLX1LRs5VPsjytHkJ7rKXs55FHR3kpsoImn5xD0Ky
6lRn8cIMolQoyN5HIGr8f5P+07hrHibve8jje/DKTssb5yEUAEmh6iGHQsRAnsUW
QoIEUOLqQCu9re2No4G52Kl2xQIjyJF7rCfxAgMBAAEwDQYJKoZIhvcNAQEFBQAD
ggEBAGHrya/ZkiAje2kHsOajXMlO2+y1iLfUDcRLuEWpUa8sI5EM4YtemQrsupFp
8lVYG5C4Vh8476oF9t8Wex5eH3ocwbSvPIUqE07hdmrubiMq4wxFVRYq7g9lHAnx
l+bABuN/orbAcPcGAGg7AkXVoAc3Fza/ZcgMcw7NOtDTEss70V9OdgCfQUJL0KdO
hCO8bQ1EaEiq6zEh8RpZe8mu+f/GYATX1I+eJUc6F6cn83oJjE9bqAVzk7TzTHeK
EBKN50C14wWtXeG7n2+ugaVO+0xnvHeUrQBLHSRyOHqxXrQQ5XmzcaBiyI0f2IQM
Hst1BVXyX0n/L/ZoYYsv5juJmDo=
-----END CERTIFICATE-----"
    @private_key = "-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAwBGx+DAot4iAz9R0vv18LvEo3UnOViV+obVe4SaZhWfB6IVf
/G2tL+mjPSCSCLfrCHtietrf/Rt5XjnSBwcXgAjeH1dpf4gP378b5ZxSng+7B5vT
nGI9R+mGCee7CDn/6Cw6SZepd0cPFQt/t1tP5c5VaQPKre36ZIlu10CQj6ZVEq3V
Qt6JENk+TQKHefsFSDqhC4BOWy19S0bOVT7I8rR5Ce6yl7OeRR0d5KbKCJp+cQ9C
supUZ/HCDKJUKMjeRyBq/H+T/tO4ax4m73vI43vwyk7LG+chFABJoeohh0LEQJ7F
FkKCBFDi6kArva3tjaOBudipdsUCI8iRe6wn8QIDAQABAoIBAG/on4JVRRQSw8LU
LiWt+jI7ryyoOUH2XL8JtzuGSwLwvomlVJT2rmbxQXx3Qr8zsgziHzIn30RRQrkF
BXu0xRuDjzBBtSVqeJ1Mc4uoNncEAVxgjb5bewswZDnXPCGB8bosMtX4OPRXgdEo
PwTtfjMOsrMaU3hd5Xu4m81tQA2BvwOlx8aYDyH0jeTnervc5uRGbeTBQG4Bu40E
rWNmXvgNq2EzTAwbbN6Ma97gw9KgXnM4Nlh29Fxb5TBeUU9lkzuTZAZIDXKIm7AG
UwMbj/A038yAumYQtThTE/3e4W3rn7F2Vko900bC4aAC1KQOAzjIeQqzqkVxWTWq
4SUFQAECgYEA/ODwifOTuI6hdZK6JRgc4wp6Rc0fkqHuxLzABXoIGuSVlWyimqIN
ZySAkpo5EW6DNraRJxNCOBmWeGPEhHGrea+JPiPEwCK0F7SxvSmg3jzNzw3Es31T
ecET7eDwuSOY9v4XDzLyiXXkEUUReD7Ng2hEYL+HaQrl5jWj4lxgq/ECgYEAwnCb
Krz7FwX8AqtFAEi6uUrc12k1xYKQfrwSxbfdK2vBBUpgB71Iq/fqP+1BittEljDG
8f4jEtMBFfEPhLzGIHaI3UiHUHXS4GetA77TRgR8lnKKpj1FcMIY2iKU479707O5
Q08pgWRUDQ8BVg2ePgbo5QjLMc/rv7UF3AHvPAECgYB/auAIwqDGN6gHU/1TP4ke
pWLi1O55tfpXSzv+BnUbB96PQgPUop7aP7xBIlBrBiI7aVZOOBf/qHT3CF421geu
8tHWa7NxlIrl/vgn9lfGYyDYmXlpb1amXLEsBVGGF/e1TGZWFDe9J5fZU9HvosVu
1xTNIvSZ6xHYI2MGZcGYIQKBgEYeebaV5C7PV6xWu1F46O19U9rS9DM//H/XryVi
Qv4vo7IWuj7QQe7SPsXC98ntfPR0rqoCLf/R3ChfgGsr8H8wf/bc+v9HHj8S5E/f
dy1e3Nccg2ej3PDm7jNsGSlwmmUkAQGHAL7KwYzcBm1UB+bycvZ1j2FtS+UckPpg
MDgBAoGALD8PkxHb4U4DtbNFSYRrUdvS9heav/yph3lTMfifNkOir36io6v8RPgb
D2bHKKZgmYlTgJrxD45Er9agC5jclJO35QRU/OfGf3GcnABkBI7vlvUKADAo65Sq
weZkdJnbrIadcvLOHOzkKC9m+rxFTC9VoN1dwK2zwYvUXfa1VJA=
-----END RSA PRIVATE KEY-----"
    @pass_phrase = "abcd"
    @wrong_private_key = "-----BEGIN CERTIFICATE-----
MIIDADCCAegCCQC9wnKoDp0BgTANBgkqhkiG9w0BAQUFADBCMQswCQYDVQQGEwJV
UzEVMBMGA1UEBwwMRGVmYXVsdCBDaXR5MRwwGgYDVQQKDBNEZWZhdWx0IENvbXBh
bnkgTHRkMB4XDTEzMDIyNjE3NDM0NloXDTE0MDIyNjE3NDM0NlowQjELMAkGA1UE
BhMCVVMxFTATBgNVBAcMDERlZmF1bHQgQ2l0eTEcMBoGA1UECgwTRGVmYXVsdCBD
b21wYW55IEx0ZDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANMxhBxF
cbw2Qr5LV5RFF2adv8W3SPm4ICXHAd0cOIqc2KS8O8YkWzP5PDsECDv+laaeNX0D
2d/TShrtTIXaOev9+pq5aC35mA9Tcmv9zdzwt0kcsVB9GaDAHXQCz7kP33/uIQNs
ndSOIV4ypSV1dZ98LUeaOhGEazo3gH8MYQpoDkDGYCM3ix+s830X8z9eJ73nXYDK
n3wrydFPMSznwa93HAcBhRcbwi5pc9Aizzo21XlCVqsUJnyxlxGl0hmyZFTEg+AS
awr59dYva1lV98+wBd3FNtqVOIDK3YTft7g9HQkcWnU32TOG77JQJriExJAKp1SO
XYVRiU+05EkxCP8CAwEAATANBgkqhkiG9w0BAQUFAAOCAQEAHjljxCd/O5N9wJXV
83bOhvUZQbXiYsjuz9syBIqslqxQ6jAIOpnOnOthc0MAWPOyW6NT/HFCOaWcPfVJ
/JwMkKulr5VILOSfWUmb2w2k26RVoaU34GF3MT8szB1B+gTdZOQ8FcXOlP4wCUE/
Wa3By7YmYloWnCpfYseZ0EZM2kTxB1+HoZO5SYwiQ0yxu1IrG/8fA1nzvxkLzlSL
kFNA6mzbPKD+xp2FtIIt+PIa/+OLUtvHSRXKy3+EyTa8KSoxxFupNwEtnw3ncigG
JhSD/puB03m/ZrORvTpFnzyV5ZzliyxsXZL8Wwrcrb/zr0/aAEUTLlQdqTTi5iRX
iGRJ3A==
-----END CERTIFICATE-----"
  end

end
