ENV["TEST_NAME"] = "functional_alias_test"
require 'test_helper'

class AliasTest < ActiveSupport::TestCase
  def setup
    @random = rand(1000000000)
    @login = "user#{@random}"
    @user = CloudUser.new(login: @login)
    @user.private_ssl_certificates = true
    @user.save
    Lock.create_lock(@user.id)
    stubber
    @namespace = "ns#{@random}"
    @domain = Domain.new(namespace: @namespace, owner:@user)
    @domain.save
    @app_name = "app#{@random}"
    @app = Application.create_app(@app_name, cartridge_instances_for(:php), @domain)
    @app.save
    set_certificate_data
  end

  def teardown
    begin
      @domain.applications.each do |app|
        app.delete
      end
      @domain.delete
      @user.delete
    rescue
    end
  end

  test "create and find and and update and delete alias" do
    server_alias = "as.#{@random}"
    @app.add_alias(server_alias)
    assert_equal(1, @app.aliases.length)

    as = @app.aliases.find_by(fqdn: server_alias)
    assert_equal(server_alias, as.fqdn)
    assert_equal(false, as.has_private_ssl_certificate)
    h = as.to_hash
    assert_equal(server_alias, h["fqdn"])
    assert_equal(false, h["has_private_ssl_certificate"])

    @app.update_alias(server_alias, @ssl_certificate, @private_key, @pass_phrase)
    as = @app.aliases.find_by(fqdn: server_alias)
    assert_equal(server_alias, as.fqdn)
    assert_equal(true, as.has_private_ssl_certificate)

    @app.remove_alias(server_alias)
    assert_equal(0, @app.aliases.length)
  end

  test "create and find and update and delete alias with certificate" do
    server_alias = "as.#{@random}"
    @app.add_alias(server_alias, @ssl_certificate, @private_key, @pass_phrase)
    assert_equal(1, @app.aliases.length)

    as = @app.aliases.find_by(fqdn: server_alias)
    assert_equal(server_alias, as.fqdn)
    assert_equal(true, as.has_private_ssl_certificate)

    @app.update_alias(server_alias)
    as = @app.aliases.find_by(fqdn: server_alias)
    assert_equal(server_alias, as.fqdn)
    assert_equal(false, as.has_private_ssl_certificate)

    @app.remove_alias(server_alias)
    assert_equal(0, @app.aliases.length)
  end

  test "create dulicate alias" do
    server_alias = "as.#{@random}"
    @app.add_alias(server_alias)
    assert_equal(1, @app.aliases.length)

    as = @app.aliases.find_by(fqdn: server_alias)
    assert_equal(server_alias, as.fqdn)

    app2 = Application.create_app("app2", cartridge_instances_for(:php), @domain)
    app2.save
    assert_raise(OpenShift::UserException){app2.add_alias(server_alias)}

  end

  test "create alias with bad inputs" do
    #invalid chars
    server_alias = "dfh%44$"
    assert_raise(OpenShift::UserException){@app.add_alias(server_alias)}
    #empty
    server_alias = ""
    assert_raise(OpenShift::UserException){@app.add_alias(server_alias)}
    #too long
    server_alias = "01234567890123456789012345678901234567890123456789012345678901234567890123456789
01234567890123456789012345678901234567890123456789012345678901234567890123456789
01234567890123456789012345678901234567890123456789012345678901234567890123456789
01234567890123456789012345678901234567890123456789012345678901234567890123456789"
    assert_raise(OpenShift::UserException){@app.add_alias(server_alias)}
    #no private key
    server_alias = "as.#{@random}"
    assert_raise(OpenShift::UserException){@app.add_alias(server_alias, @ssl_certificate)}

    #bad private key
    server_alias = "as.#{@random}"
    assert_raise(OpenShift::UserException){@app.add_alias(server_alias, @ssl_certificate, "abcd")}

    #wrong private key
    server_alias = "as.#{@random}"
    assert_raise(OpenShift::UserException){@app.add_alias(server_alias, @ssl_certificate, @private_key2)}

    #bad certificate
    server_alias = "as.#{@random}"
    assert_raise(OpenShift::UserException){@app.add_alias(server_alias, "ABCDEFG", @private_key, @pass_phrase)}
  end

  test "update alias with bad inputs" do
    server_alias = "as.#{@random}"
    #non-existent alias
    assert_raise(Mongoid::Errors::DocumentNotFound){@app.update_alias(server_alias)}
    #no private key
    @app.add_alias(server_alias)
    assert_raise(OpenShift::UserException){@app.update_alias(server_alias, @ssl_certificate)}

    #bad private key
    server_alias = "as.#{@random}"
    assert_raise(OpenShift::UserException){@app.update_alias(server_alias, @ssl_certificate, "abcd")}

    #wrong private key
    server_alias = "as.#{@random}"
    assert_raise(OpenShift::UserException){@app.update_alias(server_alias, @ssl_certificate, @private_key2)}

    #bad certificate
    server_alias = "as.#{@random}"
    assert_raise(OpenShift::UserException){@app.update_alias(server_alias, "ABCDEFG", @private_key, @pass_phrase)}
  end

  test "remove alias with bad inputs" do
    server_alias = "as.#{@random}"
    #non-existent alias
    assert_raise(Mongoid::Errors::DocumentNotFound){@app.remove_alias(server_alias)}
  end
=begin
  test "create alias rollback" do
    server_alias = "as#{@random}"
    #verify that alias is rolled back if add_ssl_cert fails
    @container.stubs(:add_ssl_cert).returns(ResultIO.new(1))
    assert_raise(Exception){ @app.add_alias(server_alias, @ssl_certificate, @private_key, @pass_phrase)}
    assert_raise(Mongoid::Errors::DocumentNotFound){@app.aliases.find_by(fqdn: server_alias)}
  end

  test "update alias with new cert rollback" do
    server_alias = "as#{@random}"
    #verify that alias is rolled back if add_ssl_cert fails
    @container.stubs(:add_ssl_cert).returns(ResultIO.new(1))

    @app.add_alias(server_alias)
    #verify that there no cert
    as = @app.aliases.find_by(fqdn: server_alias)
    assert_equal(false, as.has_private_ssl_certificate)
    #fail an update of certificate
    assert_raise(Exception){ @app.update_alias(server_alias, @ssl_certificate, @private_key, @pass_phrase)}
    #verify that it was rolled back
    as = @app.aliases.find_by(fqdn: server_alias)
    assert_equal(false, as.has_private_ssl_certificate)

  test "update alias with no cert rollback" do
    server_alias = "as#{@random}"
    #verify that alias cannot be rolled back if remove_ssl_cert fails
    @container.stubs(:remove_ssl_cert).returns(ResultIO.new(1))

    @app.add_alias(server_alias, @ssl_certificate, @private_key, @pass_phrase)
    #verify that is has certificate
    as = @app.aliases.find_by(fqdn: server_alias)
    assert_equal(true, as.has_private_ssl_certificate)
    #fail to remove certificate
    assert_raise(Exception){ @app.update_alias(server_alias)}
    #verify that it cannot be rolled back
    as = @app.aliases.find_by(fqdn: server_alias)
    assert_equal(false, as.has_private_ssl_certificate)
  end

  test "remove alias rollback" do
    server_alias = "as#{@random}"
    @app.add_alias(server_alias, @ssl_certificate, @private_key, @pass_phrase)
    #verify that is has certificate
    as = @app.aliases.find_by(fqdn: server_alias)
    assert_equal(true, as.has_private_ssl_certificate)
    #verify that alias is partially rolled back if remove_ssl_cert fails
    @container.stubs(:remove_ssl_cert).returns(ResultIO.new(1))
    #verify that remove certificate failed
    assert_raise(Exception){ @app.remove_alias(server_alias)}
    #verify that the alias exists but the removal of certificate cannot be rolled back
    as = @app.aliases.find_by(fqdn: server_alias)
    assert_equal(true, as.has_private_ssl_certificate)
  end

=end

  def set_certificate_data
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
    @private_key2 = "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA0zGEHEVxvDZCvktXlEUXZp2/xbdI+bggJccB3Rw4ipzYpLw7
xiRbM/k8OwQIO/6Vpp41fQPZ39NKGu1Mhdo56/36mrloLfmYD1Nya/3N3PC3SRyx
UH0ZoMAddALPuQ/ff+4hA2yd1I4hXjKlJXV1n3wtR5o6EYRrOjeAfwxhCmgOQMZg
IzeLH6zzfRfzP14nveddgMqffCvJ0U8xLOfBr3ccBwGFFxvCLmlz0CLPOjbVeUJW
qxQmfLGXEaXSGbJkVMSD4BJrCvn11i9rWVX3z7AF3cU22pU4gMrdhN+3uD0dCRxa
dTfZM4bvslAmuITEkAqnVI5dhVGJT7TkSTEI/wIDAQABAoIBAQCfHiJ8LnInrPYS
a697fabI4LeZHqOzyd8mt06XKekLvmqXi165xbCVcwXHLR2LHh/gXjjMjPc9ZPLj
YMCT5LxZKo0CwAhXA0Nm4KdH5/yPpylgw2ZwzyBc9gH64xdgRi5NM7vZ2Z78g21u
jFfS5jGNzMBMv01a31rujNyaXFhMvoQUu6uHD7arIZ22jy0ru/G3rAwDnpLTWuNp
fRegVzbVMxw3f4SP54OHAWlcEeFMhv/a6XmpPr3PfCrRlSdMC0aFDYFqqzjYZWks
Jx6Q2/OKt49+980rBWfOpLkJSl4rNzR48+dtC6+97uIM3gyHNx5iDIxlJrBW+Gzj
wc2rhyL5AoGBAPo4KOTuno+UKJozd0olXeOU58TYwmIU68w30PTUbOGc8jfxJ6Rc
iC6ndDmdXL18iDBYJ/8hTlkCtS1g3dum3gOiUf5E9Ba4wsK/UFWzffHW54odTO5L
kiA0pAhSDiTQqgBJFUM0JYI/cRW3f08fqRbzIW0OP2EB/zCBdn5tu6sbAoGBANgS
jNZczDfdCcUkVdfODnGcP4TVCrXqHwHlShKnbT0njaaZGG4DHSMUtIgxZgchkoWT
h85+vjD9EX8+heVdQOYbAUsA5OBMBh0vyX9SCYtnhpIK+eh5LpQ8Li0FN858+N8/
42s4E2X+9u+QhUZKyPlmil4t92Z/kw0qo90Mq/PtAoGABRvEafgdMJ07vvoyA0eE
BTNzD+fFAC+hKMgy8eysVGbZ4x5/SrHA7gLpMovt6shyF1qVZnYNnW+at1R08xkT
C0vzFJffy971yvgQ8c76UUer7nvuqCbO0u2AM9NJCqNf9SWI05hq85/L9T+Lz9e7
ogZQtmNGE/rwdNMP0kD3ReUCgYEAk6QRQgREssNBgsiyM3SkH/NA39XmrKjeKSBw
fdCTbx8Qxk6EB9/uz+K8/PasHaFOCiHlwS6PbM/vXb/uI+yVhOXc+1AQFEc+QkE9
8NawmOXTaQVBAB2Vu0pnzvFq0ZhJQdrY3ZGCh8YxGz7oIkDFlM0BLRtBmnL/mxaQ
w2F+OX0CgYBJw4ruBVw+EcFfT3/0zCrJIxLLeJjFuz+HYXApkFsBQLGtnYz97Oww
av6o/wufvVqGc81SPDmEMsEasXgeMyL7MTsShh26yFzrDoGN2djn5uT+f8Y1WdFN
xJFFvCG76BmKcC1VJCbRByY7Ju3kpDEX6sYkmDytrZsVHK/iW5MM6A==
-----END RSA PRIVATE KEY-----"
  end
end
