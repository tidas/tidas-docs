#Tidas Ruby Middleware API Doc

## Configuration

Tidas is configured either with preset ENVs, or with a configuration method explained in the API below

Configuration Params:

* **server**: `<Tidas::Configuration.server>` The tidas production endpoint. You must set this to `https://app.passwordlessapps.com`
* **api_key**: `<Tidas::Configuration.api_key>` The API key you use to authenticate your requests to our backend
* **application**: `<Tidas::Configuration.application>` The application identifier you use to silo your users within our database
* **timeout**: `<Tidas::Configuration.timeout>` If our default of 20s is too long a timeout for you, optionally set a shorter one for your implementation

## API v0.1

#### Check Tidas availability ####

This call is used to check the availability of the Tidas servers. 

**API Call:** `Tidas.Ping`

Parameters:

* **None**

Returns:
* **Success**: `<Tidas::SuccessfulResult>` SuccessfulResult object containing "Pong!"
* **Bad Request**: `<Tidas::ErrorResult>` ErrorResult explaining what happened
* **Timeout**: `<Tidas::TimeoutError>` Timeout Error Object
* **50x**: `<Tidas::ServerError>` Server Error Object

#### Configure Tidas ####

This section is used to set needed ENVs for Tidas to operate.

**API Call:** `Tidas::Configure`

Parameters:

* **server**: `<String>` The tidas production endpoint. You must set this to `https://app.passwordlessapps.com`
* **api_key**: `<String>` The API key you use to authenticate your requests to our backend
* **application**: `<String>` The application identifier you use to silo your users within our database
* **timeout**: `<String>` If our default of 20s is too long a timeout for you, optionally set a shorter one for your implementation

Returns:

* **Success**: nil

Example:

```ruby
  Tidas::Configuration.configure(
    server: 'https://app.passwordlessapps.com',
    api_key: 'c8bbe73e1d6d0ba28b439599091140b1',
    application: 'Javelin',
    timeout: 1
  )
```

#### Enroll Identity ####

This call is used to store a public key in our database. You can optionally supply a `tidas_id` if you want identity lookups to use your id conventions. Additionally, you can send an `overwrite` option to update an existing ID with a new identity object.

**API Call:** `Tidas::Identity.enroll`

Parameters:

* **data**: `<Tidas::EnrollmentData>`enrollment blob from client device
* **options/tidas_id**: `<String>` id to store key info with (optional: if not included, we will return one to you)
* **options/overwrite**: `<Boolean>` supply `true` to allow overwriting existing public key info with this request

Returns:

* **Success**: `<Tidas::SuccessfulResult>` Contains tidas_id for you to store/ use to look up the saved identity
* **Failure**: `<Tidas::ErrorResult>` Contains errors raised when attempting to create or update the `Tidas::Identity`

Examples:

```ruby
Tidas::Identity.enroll(data:<Tidas::EnrollmentData>)
```

```ruby
Tidas::Identity.enroll(
  data:<Tidas::EnrollmentData>,
  options: {
    tidas_id: "e_23423",
    overwrite: true
  }
)
```

#### Validate Data####

This call is used to validate data using a provided hash, signature, and a stored public key from our database. The call works by looking up a user with the provided tidas_id, then validating that the data provided was signed with that users' public key. Upon successful validation, the data is made available in the `SuccessfulResult` object.

**API Call:** `Tidas::Identity.validate`

Parameters:

* **data**: `<Tidas::ValidationData>`validation blob from client device
* **tidas_id**: `<String>` id to validate data against a specific user

Returns:

* **Success**: `<Tidas::SuccessfulResult>` Contains tidas_id and the data which was just validated, for you to use on your backend
* **Failure**: `<Tidas::ErrorResult>` Contains errors raised when attempting to create or validate the data

Examples:

```ruby
Tidas::Identity.validate(data:<Tidas::ValidationData>, tidas_id:"e_23423")
```

#### Deactivate User####

This call is used to deactivate users which you no longer wish to validate data from. Users are not deleted, but made inactive in case they decide to use the application again

**API Call:** `Tidas::Identity.deactivate`

Parameters:

* **tidas_id**: `<String>` id of user you wish to deactivate

Returns:

* **Success**: `<Tidas::SuccessfulResult>` Contains tidas_id and a message confirming deactivation
* **Failure**: `<Tidas::ErrorResult>` Contains errors raised when attempting to deactivate the user

Examples:

```ruby
Tidas::Identity.deactivate(tidas_id:'24jdpoifj24')
```

#### Activate User####

This call is used to activate users which you previously deactivated, and want to begin validating data from again.

**API Call:** `Tidas::Identity.activate`

Parameters:

* **tidas_id**: `<String>` id of user you wish to activate

Returns:

* **Success**: `<Tidas::SuccessfulResult>` Contains tidas_id and a message confirming activation
* **Failure**: `<Tidas::ErrorResult>` Contains errors raised when attempting to activate the user

Examples:

```ruby
Tidas::Identity.activate(tidas_id:'24jdpoifj24')
```

#### List Users####

This call is used to list users of your application, both active and deactivated. public keys are trimmed for brevity, but the accompanying `get(<tidas_id>)` method will return this info if you ask for a specific user's information

**API Call:** `Tidas::Identity.index`

Parameters:

* **None**

Returns:

* **Success**: `Array[<Tidas::Identity>]` An array of tidas identity objects
* **Failure**: `<Tidas::ErrorResult>` Contains errors raised when attempting to list users

Examples:

```ruby
Tidas::Identity.index
```

#### Get User Info####

This call is used to retrieve information about a specific user, including their public_key

**API Call:** `Tidas::Identity.get`

Parameters:

* **tidas_id**: `<String>` id of user you wish to get information for

Returns:

* **Success**: `<Tidas::Identity>` Contains tidas identity object with the requested user's info
* **Not Found**: `Array[]` Empty Array 
* **Failure**: `<Tidas::ErrorResult>` Contains errors raised when attempting to find the user

Examples:

```ruby
Tidas::Identity.get('24jdpoifj24')
```

## Tidas Error Types

List of Errors which may be encountered when using the tidas

### Application Errors (these are normal)
* **Generic App Errors**: `<Tidas::ErrorResult>` ErrorResult with a contextual message from our server
* **Timeout**: `<Tidas::TimeoutError>` Timeout Error Object
* **Connection**: `<Tidas::ConnectionError>` Error when server could not be reached
* **50x**: `<Tidas::ServerError>` Server Error Object
* **Configuration**: `<Tidas::ConfigurationError>` This error is not wrapped, and an exception will raise explaining that your tidas instance is not configured correctly
* **Arguments**: `<Tidas::ArgumentError>` This error is not wrapped, and an exception will raise explaining that you tried to make an improper call with one of the api components

### Gem Errors
* **Uncaught Gem Exception**: `<Tidas::RuntimeError>` Tidas-specific RuntimeError which shouldn't happen! Report these to us please
