ENV["TEST_NAME"] = "functional_alias_controller_test"
require 'test_helper'
class AliasControllerTest < ActionController::TestCase

  def setup
    @controller = AliasController.new

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = 'password'
    @user = CloudUser.new(login: @login)
    @user.private_ssl_certificates = true
    @user.save
    Lock.create_lock(@user.id)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
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
      @user.force_delete
    rescue
    end
  end

  test "alias create show list update and destroy" do
    server_alias = "as.#{@random}"
    post :create, {"id" => server_alias, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show, {"id" => server_alias, "domain_id" => @domain.namespace, "application_id" => @app.name}
      assert_response :success
      @request.env['HTTP_ACCEPT'] = "application/xml; version=#{version}"
      get :show, {"id" => server_alias, "domain_id" => @domain.namespace, "application_id" => @app.name}
      assert_response :success
    end
    @request.env['HTTP_ACCEPT'] = 'application/json'
    put :update, {"id" => server_alias, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    get :index , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    delete :destroy , {"id" => server_alias, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :ok
  end

  test "alias create show list update and destroy by app id" do
    server_alias = "as.#{@random}"
    post :create, {"id" => server_alias, "application_id" => @app.id}
    assert_response :created
    get :show, {"id" => server_alias, "application_id" => @app.id}
    assert_response :success
    put :update, {"id" => server_alias, "application_id" => @app.id}
    assert_response :success
    get :index , {"application_id" => @app.id}
    assert_response :success
    delete :destroy , {"id" => server_alias, "application_id" => @app.id}
    assert_response :ok
  end

  test "no or non-existent app name" do
    server_alias = "as.#{@random}"
    get :show, {"id" => server_alias, "domain_id" => @domain.namespace}
    assert_response :not_found
    put :update, {"id" => server_alias, "domain_id" => @domain.namespace}
    assert_response :not_found
    delete :destroy , {"id" => server_alias, "domain_id" => @domain.namespace}
    assert_response :not_found

    get :show, {"id" => server_alias, "domain_id" => @domain.namespace, "application_id" => "bogus"}
    assert_response :not_found
    put :update, {"id" => server_alias, "domain_id" => @domain.namespace, "application_id" => "bogus"}
    assert_response :not_found
    delete :destroy , {"id" => server_alias, "domain_id" => @domain.namespace, "application_id" => "bogus"}
    assert_response :not_found
  end

  test "no or non-existent app id" do
    server_alias = "as.#{@random}"
    get :show, {"id" => server_alias}
    assert_response :not_found
    put :update, {"id" => server_alias}
    assert_response :not_found
    delete :destroy , {"id" => server_alias}
    assert_response :not_found

    get :show, {"id" => server_alias, "application_id" => "bogus"}
    assert_response :not_found
    put :update, {"id" => server_alias, "application_id" => "bogus"}
    assert_response :not_found
    delete :destroy , {"id" => server_alias, "application_id" => "bogus"}
    assert_response :not_found
  end

  test "no or non-existent domain id" do
    server_alias = "as.#{@random}"
    post :create, {"id" => server_alias, "application_id" => @app.name}
    assert_response :not_found
    get :show, {"id" => server_alias, "application_id" => @app.name}
    assert_response :not_found
    put :update, {"id" => server_alias, "application_id" => @app.name}
    assert_response :not_found
    get :index , {"id" => server_alias, "application_id" => @app.name}
    assert_response :not_found
    delete :destroy , {"id" => server_alias, "application_id" => @app.name}
    assert_response :not_found

    post :create, {"id" => server_alias, "application_id" => @app.name, "domain_id" => "bogus"}
    assert_response :not_found
    get :show, {"id" => server_alias, "application_id" => @app.name, "domain_id" => "bogus"}
    assert_response :not_found
    put :update, {"id" => server_alias, "application_id" => @app.name, "domain_id" => "bogus"}
    assert_response :not_found
    get :index , {"id" => server_alias, "application_id" => @app.name, "domain_id" => "bogus"}
    assert_response :not_found
    delete :destroy , {"id" => server_alias, "application_id" => @app.name, "domain_id" => "bogus"}
    assert_response :not_found
  end

  test "no or non-existent alias id using domain and app name" do
    post :create, {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :unprocessable_entity
    get :show, {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found
    put :update, {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found
    delete :destroy , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found

    get :show, {"domain_id" => @domain.namespace, "application_id" => @app.name, "id" => "bogus"}
    assert_response :not_found
    put :update, {"domain_id" => @domain.namespace, "application_id" => @app.name, "id" => "bogus"}
    assert_response :not_found
    delete :destroy , {"domain_id" => @domain.namespace, "application_id" => @app.name, "id" => "bogus"}
    assert_response :not_found
  end

  test "no or non-existent alias id using app id" do
    post :create, {"application_id" => @app.id}
    assert_response :unprocessable_entity
    get :show, {"application_id" => @app.id}
    assert_response :not_found
    put :update, {"application_id" => @app.id}
    assert_response :not_found
    delete :destroy , {"application_id" => @app.id}
    assert_response :not_found

    get :show, {"application_id" => @app.id, "id" => "bogus"}
    assert_response :not_found
    put :update, {"application_id" => @app.id, "id" => "bogus"}
    assert_response :not_found
    delete :destroy , {"application_id" => @app.id, "id" => "bogus"}
    assert_response :not_found
  end

  test "no private key" do
    server_alias = "as.#{@random}"
    post :create, {"id" => server_alias, "domain_id" => @domain.namespace, "application_id" => @app.name, 
      "ssl_certificate" => @ssl_certificate}
    assert_response :unprocessable_entity
    post :create, {"id" => server_alias, "application_id" => @app.id, 
      "ssl_certificate" => @ssl_certificate}
    assert_response :unprocessable_entity
  end

  test "no user capability by domain and app name" do
    @user.private_ssl_certificates = false
    @user.save!

    server_alias = "as.#{@random}"
    post :create, {"id" => server_alias, "domain_id" => @domain.namespace, "application_id" => @app.name, 
      "ssl_certificate" => @ssl_certificate, "private_key" => @private_key, "pass_phrase" => @pass_phrase}
    assert_response :forbidden

    post :create, {"id" => server_alias, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :created

    put :update, {"id" => server_alias, "domain_id" => @domain.namespace, "application_id" => @app.name, 
      "ssl_certificate" => @ssl_certificate, "private_key" => @private_key, "pass_phrase" => @pass_phrase}
    assert_response :forbidden
  end

  test "no user capability by app id" do
    @user.private_ssl_certificates = false
    @user.save
    server_alias = "as.#{@random}"
    post :create, {"id" => server_alias, "application_id" => @app.id, 
      "ssl_certificate" => @ssl_certificate, "private_key" => @private_key, "pass_phrase" => @pass_phrase}
    assert_response :forbidden

    post :create, {"id" => server_alias, "application_id" => @app.id}
    assert_response :created

    put :update, {"id" => server_alias, "application_id" => @app.id, 
      "ssl_certificate" => @ssl_certificate, "private_key" => @private_key, "pass_phrase" => @pass_phrase}
    assert_response :forbidden
  end

  test "get alias in all versions" do
    server_alias = "as.#{@random}"
    post :create, {"id" => server_alias, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show, {"id" => server_alias, "domain_id" => @domain.namespace, "application_id" => @app.name}
      assert_response :ok, "Getting alias for version #{version} failed"
    end
    @request.env['HTTP_ACCEPT'] = "application/json"
  end

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
