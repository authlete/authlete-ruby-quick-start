authlete-ruby-quick-start
=========================

# Overview

A sample implementation of OAuth 2.0 server in Ruby using [Authlete]
(https://www.authlete.com/).

This code demonstrates how easy it is to implement OAuth 2.0 server
with **Authlete**. All you have to do is to register the definition of
your service into Authlete and to implement your ***authentication
callback endpoint***. To your surprise, you do not have to implement
the [authorization endpoint](https://tools.ietf.org/html/rfc6749#section-3.1)
and the [token endpoint](https://tools.ietf.org/html/rfc6749#section-3.2)
of your service.


<hr>
# 1. Set Up Service and Client Application

## 1.1 Register Your Account

1. Go to "[Sign Up for Evaluation](https://www.authlete.com/user/registration/evaluation)" page.
2. Register your account, and an email for confirmation will be sent to you.
3. Open the email from Authlete titled "Authlete Registration Confirmation".
4. Click "Complete Registration" button in the email, and your default browser will open the user verification page.
5. Input your login ID (or email address) and password in the page.
6. Click "Download" button to download your API key and API secret.
7. Save the downloaded JSON file (`service-owner.json`) in your local machine.


## 1.2 Download This Source

Execute the following command to download this source.

```sh
$ git clone http://github.com/authlete/authlete-ruby-quick-start.git
$ cd authlete-ruby-quick-start
```


## 1.3 Register Your Service

Execute the following command to register the definition of your service.
${SERVICE_OWNER_API_KEY} and ${SERVICE_OWNER_API_SECRET} in the command
line must be replaced with the values of `apiKey` and `apiSecret` in
`service-owner.json`.

```sh
$ curl -v --user ${SERVICE_OWNER_API_KEY}:${SERVICE_OWNER_API_SECRET} \
       -H "Content-Type:application/json;charset=UTF-8" \
       -d @service-original.json -o service.json \
       https://evaluation-dot-authlete.appspot.com/api/service/create
```

Note: The response from Authlete API may take a long time (a few tens of
seconds) if Authlete server is in sleep mode when you access it.


## 1.4 Register Your Client Application

Execute the following command to register the definition of your client
application. ${SERVICE_API_KEY} and ${SERVICE_API_SECRET} in the command
line must be replaced with the values of `apiKey` and `apiSecret` in
`service.json` (not `service-owner.json`).

```sh
$ curl -v --user ${SERVICE_API_KEY}:${SERVICE_API_SECRET} \
       -H "Content-Type:application/json;charset=UTF-8" \
       -d @client-original.json -o client.json \
       https://evaluation-dot-authlete.appspot.com/api/client/create
```


## 1.5 Make an Authorization Request

Access the following URL with your browser. Of course, don't forget to
replace ${SERVICE_API_KEY} and ${CLIENT_ID} in the URL with your service's
API key and your client's client ID. The value of ${CLIENT_ID} can be found
in `client.json` which was created as the result of the `curl` command above.

```
https://evaluation-dot-authlete.appspot.com/api/auth/authorization/direct/${SERVICE_API_KEY}
?response_type=code&client_id=${CLIENT_ID}
```

This is an [authorization request](https://tools.ietf.org/html/rfc6749#section-4.1.1)
to the [authorization endpoint](https://tools.ietf.org/html/rfc6749#section-3.1)
of your service. On success, you will see an authorization UI like below.

![Authorization UI](images/authorization-ui.png)


## 1.6 Authorize The Client Application

Input any arbitrary strings to "Login ID" and "Password" fields (any value
other than "nobody" is accepted as a valid login ID). Then, press "Authorize"
button. This will redirect your browser to the redirection endpoint and you
will see a page like below.

![Redirection Endpoint](images/redirection-endpoint.png)

Note: The behavior of the authentication here comes from the mock implementation
provided by Authlete. You have to implement your own authentication callback
endpoint to check whether the presented credentials (login ID and password)
are valid or not. This topic is covered later in this README.

Note: The redirection endpoint you see here is the mock implementation provided
by Authlete. A redirection endpoint is supposed to be implemented by a developer
of a client application.


## 1.7 Make a Token Request

The mock implementation of the redirection endpoint contains a form to make
a [token request](https://tools.ietf.org/html/rfc6749#section-4.1.3) to the
[token endpoint](https://tools.ietf.org/html/rfc6749#section-3.2) of your
service. Input "/api/auth/token/direct/${SERVICE_API_KEY}" to "URL" field
(replace ${SERVICE_API_KEY} with your service's API key) and your client's
client ID to "client_id" field. Then, press "Submit" button.

On success, you will get a JSON file like below which contains an access
token and other parameters.

```js
{
  "access_token": "j3JFfgf9p1nuxdQ3Y9fiYisznUzFHmeFagdo7U-do4F",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "profile",
  "refresh_token": "v7L3KFAMEjchrPJe9Sm0vyXeBbzlIfxdc1zxhDOgwvd"
}
```

Note that an authorization code expires in 10 minutes (it is recommended
by RFC 6749), so you have to make a token request without a big delay
after an authorization code was issued.


## 1.8 Summary

If you have reached here without any trouble, it means that your service has
completed [Authorization Code Flow](https://tools.ietf.org/html/rfc6749#section-4.1)
defined in [RFC 6749](https://tools.ietf.org/html/rfc6749) (OAuth 2.0) without
your writing any code. Congratulations!

The next step is to implement your own *authentication callback endpoint* to
authenticate end-users.


<hr>
# 2. Authentication Callback Endpoint

## 2.1 Install Authlete Gem

Execute the following command to install the [authlete gem](https://rubygems.org/gems/authlete).

```sh
$ gem install authlete
```


## 2.2 Start an Authentication Server

Execute the following command to start a sample authentication server which
implements an *authentication callback endpoint*.

```sh
$ rackup --port 9000 authentication-server.ru &
```


## 2.3 Make an Authentication Callback Request

Make an authentication callback request to test the authentication server.

```sh
$ curl -v --user authentication-api-key:authentication-api-secret \
       -H 'Content-Type:application/json;charset=UTF-8' \
       -d @authentication-request.json \
       http://localhost:9000/authentication
```

On success, you will get a response show below.

```js
{
  "authenticated": true,
  "subject": "user",
  "claims": "{\"given_name\":\"user\"}"
}
```

The authentication callback request that you made just now by the `curl`
command simulates a request from Authlete, and the response in JSON format
shown above is an example of authentication callback responses that your
authentication server is supposed to build.

Details about the requirements for an authentication callback endpoint
are described soon later.


## 2.4 Make an Authentication Server Public

Your implementation of an authentication callback endpoint must be
accessible from Authlete. This means that you have to put your authentication
server on a machine which is publicly accessible via the Internet. However,
it is cumbersome for testing purposes. So, let's use [Localtunnel]
(http://localtunnel.me/) for now. *"Localtunnel will assign you a unique
publicly accessible url that will proxy all requests to your locally running
webserver."*

Install Localtunnel

```sh
$ npm install -g localtunnel
```

and then start Localtunnel for your authentication server which is running
on the port number 9000.

```sh
$ lt --port 9000
your url is: https://monmcbvmqj.localtunnel.me
```

On success, `lt` command reports a URL that has been assigned. In the above
example, `https://monmcbvmqj.localtunnel.me` is the URL.

Make an authentication call request to the proxy.

```sh
$ curl -v --user authentication-api-key:authentication-api-secret \
       -H 'Content-Type:application/json;charset=UTF-8' \
       -d @authentication-request.json \
       https://monmcbvmqj.localtunnel.me/authentication
```

On success, you will get the same JSON response as illustrated in the
previous section.


## 2.5 Register Your Authentication Callback Endpoint

You need to tell Authlete where your authentication callback endpoint is.
Open `service.json` with a text editor and change the value of
`authenticationCallbackEndpoint`. To be concrete, replace

```js
"authenticationCallbackEndpoint":
  "https://evaluation-dot-authlete.appspot.com/api/mock/authentication",
```

with

```js
"authenticationCallbackEndpoint":
  "https://monmcbvmqj.localtunnel.me/authentication",
```

After saving `service.json`, update the metadata of your service by calling
Authlete's /service/update API.

```sh
$ curl -v --user ${SERVICE_OWNER_API_KEY}:${SERVICE_OWNER_API_SECRET} \
       -H "Content-Type:application/json;charset=UTF-8" \
       -d @service.json \
       https://evaluation-dot-authlete.appspot.com/api/service/update/${SERVICE_API_KEY}
```


## 2.6 Test Connection between Your Authentication Server and Authlete

Make an authorization request again using the same procedure as described in
"1.5 Make an Authorization Request". In the displayed authorization UI, input
different strings to "Login ID" field and "Password" field, and then press
"Authorize" button. If your authentication server responded to an authentication
callback request from Authlete, you will see an error message, "Login ID and/or
password are wrong." This error is caused because the authentication logic of
the sample implementation (= `authentication_user` method in
`authentication-server.rb`) regards given credentials as valid only when the
ID and the password are equal.

After confirming the login failure, input the same strings to "Login ID" field
and "Password" field and press "Authorize" button. This time, you will be
authorized successfully. Complete the authorization code flow (= make a token
request as described in "1.7 Make a Token Request") and get an access token.
Write down the access token since it will be used later to test protected
resouce endpoints.


## 2.7 Requirements for Authentication Callback Endpoint

### 2.7.1 Input to Authentication Callback Endpoint

* Basic Authentication

    If `authenticationCallbackEndpointApiKey` and `authenticationCallbackEndpointApiSecret`
    are registered, Authlete uses them to build the value of `Authorization`
    HTTP header for [Basic Authentication](http://tools.ietf.org/html/rfc2617).
    Implementations of authentication callback endpoint should check whether
    presented API key and API secret via Basic Authentication are equal to
    the registered ones. This is highly recommended.

* HTTP method

    `POST` method.

* Content-Type

    `application/json`

* Data Format

    The entity body of an authentication callback request is JSON. The properties
    contained in the JSON are `serviceApiKey`, `clientId`, `id`, `password`,
    `claims` and `claimsLocales`. [AuthenticationCallbackRequest.java]
    (https://github.com/authlete/authlete-java-common/blob/master/src/main/java/com/authlete/common/dto/AuthenticationCallbackRequest.java)
    in [authlete-java-common](https://github.com/authlete/authlete-java-common)
    represents the latest format. `AuthenticationCallbackRequest.rb` in
    [authlete gem](https://rubygems.org/gems/authlete) represents the format, too.

    `serviceApiKey` is the API key of your service. `clientId` is the ID of
    the client application which has triggered the authentication callback
    request.

    `id` and `password` properties hold the values that the end-user input to
    "Login ID" field and "Password" field in the authorization UI displayed at
    the authorization endpoint. Basically, authentication should be performed
    for these values.

    `claims` is a string array which lists claims names (such as `given_name`)
    requested by an authorization request. 'Claim' is a piece of information
    about an end-user. Some standard claim names are defined in
    "[5.1. Standard Claims](http://openid.net/specs/openid-connect-core-1_0.html#StandardClaims)"
    in [OpenID Connect Core 1.0](http://openid.net/specs/openid-connect-core-1_0.html).
    You can list up claim names as the value of `supportedClaims` which your
    service intends to support. Note that claim names may be followed by a locale
    tag like `given_name#ja`. See "[5.2.  Claims Languages and Scripts]
    (http://openid.net/specs/openid-connect-core-1_0.html#ClaimsLanguagesAndScripts)"
    for details.

    `claimsLocales` is a string array which lists locale names. The values
    come from `claims_locales` request parameter contained in the authorization
    request which has triggered the authentication callback request. See
    "[5.2.  Claims Languages and Scripts]
    (http://openid.net/specs/openid-connect-core-1_0.html#ClaimsLanguagesAndScripts)"
    for details.


### 2.7.2 Output from Authentication Callback Endpoint

* Content-Type

    `application/json;charset=UTF-8`

* Recommended HTTP headers

    `Cache-Control: no-store`<br>
    `Pragram: no-cache`

* Data Format

    The entity body of an authentication callback response must be JSON.
    The properties expected to be contained in the JSON are `authenticated`,
    `subject` and `claims`. [AuthenticationCallbackResponse.java]
    (https://github.com/authlete/authlete-java-common/blob/master/src/main/java/com/authlete/common/dto/AuthenticationCallbackResponse.java)
    in [authlete-java-common](https://github.com/authlete/authlete-java-common)
    represents the latest format. `AuthenticationCallbackResponse.rb` in
    [authlete gem](https://rubygems.org/gems/authlete) represents the format, too.

    `authenticated` is the result of authentication. Set `true` when the
    end-user was authenticated successfully.

    `subject` is the unique identifier of the end-user in your service.
    Note that the value of `subject` is not always equal to the value of
    `id` in the authentication callback request. For example, your service
    may look up an end-user when the given `id` represents an email address
    if your service can identify an end-user from an email address. In such
    a case, the value of `subject` will probably be different from `id`.
    When `authenticated` is `false`, `subject` may remain `null`.

    `claims` is a JSON string which contains pairs of claim name and claim
    value. The following is an example which contains two pairs.

    ```js
    {
      "given_name": "Takahiko",
      "gender": "male"
    }
    ```

    See "[5. Claims](http://openid.net/specs/openid-connect-core-1_0.html#Claims)"
    for details about the format.

    Claims values returned from an authentication callback endpoint are used
    to generate an ID token. If values of requested claims are not available
    at all or if you do not want to provide claim values, `claims` may remain
    `null`.


## 2.8 About Sample Implementation

TBW


<hr>
# License

Apache License, Version 2.0


# See Also

**Authlete, Inc.**
* [Authlete Website](https://www.authlete.com/)
* [Authlete Facebook](https://www.facebook.com/authlete)
* [Authelte Twitter](https://twitter.com/authlete)
* [Authlete GitHub](https://github.com/authlete)
* [Authlete Email](mailto:support@authlete.com)
