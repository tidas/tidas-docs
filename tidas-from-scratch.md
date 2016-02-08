# Tidas from Scratch

## Intro

This article should serve as a rough template for how to get a Tidas integration off the ground.

We'll use a few terms which I define here:
- **Backend**: your backend server
- **Application**: your existing iOS application
- **tidas-server**: the Tidas server, which enrolls and validates user information
- **tidas-middleware**: the middleware we provide for installation on your backend
- **Obj-C Client Library**: the portion of code which you integrate with the Application

We also make a few assumptions about your existing infrastructure:
- The Backend is a ruby application (while we work on creating more middlewares)
- The Application already has networking code and can communicate with the Backend
- The Backend supports validating users out-of-band
- Han shot first

### Finish Setting Up Your Account
If you haven't yet, go and validate your email! You need to do this before you can make any api-calls to tidas-server.

### Download the closed-source components
- Log into the web interface to Tidas-server, and click "Account" in the navigation bar.
- Download the Obj-C Client Library and the sample application Xcode project

### Install the ruby tidas-middleware
Add tidas-middleware to your Backend's gemfile

`gem 'tidas'`

Alternatively, install tidas-middleware system-wide on the Backend

`gem install tidas`

Then "require" tidas-middleware in the Backend where you plan on doing the integration

`require "tidas"`

### Create your application in tidas-server

Head into the web interface for tidas-server, and click "Add an Application". This part is really really easy. Just type a name in, and hit "Create Application".

After creating the application, click it in the left sidebar, which brings you to a page where you get a pre-made configuration block for pasting into the Backend.

Your configuration block should look something like this:
```ruby
Tidas::Configuration.configure(
  api_key: <your api key>,
  application: <your application name>,
  server: "https://app.passwordlessapps.com",
  timeout: 20
)
```

## Configuring the Backend

It's time to configure Tidas, and set up routes in the Backend for the middleware. These routes will accept enrollment and validation requests posted from the Application. The correct way to do this varies by framework, so we'll explore a very simple example using [Sinatra](http://www.sinatrarb.com/).  

_Note: you can download the completed server template [here](https://github.com/tidas/tidas-docs/blob/master/examples/sinatra_template.rb)_

### The Test Server
The beginnings of our test server will just setup tidas-middleware and ping tidas-server to make sure things work. Here's what that looks like:

```ruby
require 'sinatra'
require 'tidas'

Tidas::Configuration.configure(
  api_key: <your api key>,
  application: <your application name>,
  server: "https://app.passwordlessapps.com",
  timeout: 20
)

get "/tidas_ping" do
	out = Tidas.ping
	out.inspect
end

```
_Once saved, open a terminal in the directory where the file exists, and type `ruby sinatra_template.rb`. Sinatra will spin up at `localhost:4567` by default._  
_Note: Sinatra does not update while running, so make sure you kill and restart the server if you're changing the code, following along at home._

### Smoke Test
Open a new terminal window to test the ping with `cURL`.

    curl localhost:4567/tidas_ping

You should get back...

    #<Tidas::SuccessfulResult:0x007f9a945463a8 @tidas_id=nil, @data=nil, @message="Pong!">

### Enrollment and Validation

Next, we're going to add routes to the test server for Enrollment and Validation.
- tidas-middleware provides a valid `TidasBlob` to test with, so we won't have to actually post any data yet.
- You can call `Tidas::Utilities::TEST_DATA_STRING` to get a valid `TidasBlob` for testing

Here's our server with "GET" versions of the new routes added:
```ruby
require 'sinatra'
require 'tidas'

Tidas::Configuration.configure(
  api_key: <your api key>,
  application: <your application name>,
  server: "https://app.passwordlessapps.com",
  timeout: 20
)

get "/tidas_ping" do
  out = Tidas.ping
  out.inspect
end

# note that we're providing an (optional) tidas_id here! If we don't, we'll have to take the one it gives us, which we can't know when the server starts
get "/process_enrollment" do
  out = Tidas::Identity.enroll(data: Tidas::Utilities::TEST_DATA_STRING, options:{tidas_id: "hello_world_id"})
  out.inspect
end

# use the tidas_id we chose earlier
get "/process_validation" do
  out = Tidas::Identity.validate(data: Tidas::Utilities::TEST_DATA_STRING, tidas_id:"hello_world_id")
  out.inspect
end

```

### Smoke Test #2

`cURL` these two routes and see what happens.

```bash
curl localhost:4567/process_enrollment
#<Tidas::SuccessfulResult:0x007fb1f29f70d0 @tidas_id="hello_world_id", @data=nil, @message="Identity successfully saved">

curl localhost:4567/process_validation
#<Tidas::SuccessfulResult:0x007f847426b808 @tidas_id="hello_world_id", @data="token", @message="Data passes validation">
```

### Sending Data

Change your `GET` routes to `POST`s, and modify your methods to parse out the parameters from the input. You can send data to the Backend however you choose, but we're going to use JSON with our example server. The updated server looks like this:

```ruby
require 'sinatra'
require 'tidas'

Tidas::Configuration.configure(
  api_key: <your api key>,
  application: <your application name>,
  server: "https://app.passwordlessapps.com",
  timeout: 20
)

get "/tidas_ping" do
  out = Tidas.ping
  out.inspect
end

post "/process_enrollment" do
  parsed_data = JSON.parse(request.body.read, quirks_mode:true)
  out = Tidas::Identity.enroll(data: parsed_data["tidasBlob"], options:{tidas_id: parsed_data['tidas_id']})
  out.inspect
end

post "/process_validation" do
  parsed_data = JSON.parse(request.body.read, quirks_mode:true)
  out = Tidas::Identity.validate(data: parsed_data["tidasBlob"], tidas_id: parsed_data['tidas_id'])
  out.inspect
end

```

Here's a JSON template to drop your values into, with pre-escaped quotes:

_Note: The names `tidasBlob` and `tidas_id` are arbitrary, since I'm parsing this JSON before providing any values to the middleware. The crazy string is a fully formatted TidasBlob string which should pass both enrollment and validation for testing_

```
"{\"tidasBlob\": \"AAEAAAAAAQUAAAB0b2tlbgIIAAAArjLCVQAAAAADFAAAAOampSqv22ZcJqGA8NycnekorHaIBEYAAAAwRAIgR318ZQZ2lZqMCtOmNZJeqaeFM4CXRK1MoV4V2nJoRlACIBQp4Aujc2Ks8t9ouJn//pVOhUFjqXhZltKBbz/GoSC9BUEAAAAELRQfUdYVN0zMrWllimOc9phemEbyqizT2NmPmnAnHrQnE+oTP0CLVFOZjDLhLdyoawcmMT6VurgDCkU9HW9zIg==\",\"tidas_id\": \"<optional tidas_id>\"}"
```

### Doing it Live - Enrollment

Once your json blob is built with the template above, you can use `curl -d` to send a `POST`.

```bash
curl -d <your json> localhost:4567/process_enrollment
```

If your request was successful, you'll see a `SuccessfulResult` object return and get printed to the console  
`#<Tidas::SuccessfulResult:0x007ffe9ccef660 @tidas_id="e_24323", @data=nil, @message="Identity successfully saved">`

If there was a problem with your request, you'll get an `ErrorResult` instead, explaining what went wrong:  
 `#<Tidas::ErrorResult:0x007ffe9d8a63a0 @tidas_id=nil, @errors=["This id is associated with another user"]>`

### Doing it Live - Validation

```bash
curl -d <your json> localhost:4567/process_validation
```

If your request was successful, you'll see a `SuccessfulResult` object return and get printed to the console.  
`#<Tidas::SuccessfulResult:0x007ffe9cc69948 @tidas_id="e_24323", @data="token", @message="Data passes validation">`

As with enrollment, if there was a problem with your request, you'll get an `ErrorResult` instead, explaining what went wrong:  
`#<Tidas::ErrorResult:0x007ffe9cc39a90 @tidas_id=nil, @errors=["Unknown identity for your application"]>`

_Note: Inside the `data` field of a `SuccessfulResult` from a call to `Tidas::Identity.validate(...)` is the data you sent up from your phone. The `TEST_DATA_STRING` contains the string "token" as the data object._

## Using the Obj-C Client Library

Finally, we'll set up the application, so that we can generate real `TidasBlob`s on actual phones.  
Please note that since Tidas relies on the Secure Enclave inside of TouchID-enabled devices, you **cannot** test Tidas on a simulator or iOS devices without TouchID.

The Obj-C Client Library is contained within the folder `libTidas`. Add the `libTidas` folder to your Xcode project, and choose where to integrate Tidas into your codebase.  

After adding the folder to your project, instantiate a `Tidas` singleton within the Application:

```objective-c
Tidas *ti = [Tidas sharedInstance];
```

Then, just use one of the API methods to generate a 	`TidasBlob` for the desired action.  

Here's a slightly modified version of the enrollment request from our sample Application:
```objective-c
- (void)enroll {
  Tidas *ti = [Tidas sharedInstance];
  __block NSString *enrollmentData;
  [ti generateEnrollmentRequestWithCompletion:^(NSString *string, NSError *err) {
    if (string) {
      enrollmentData = string;
    }
    else{
      NSLog(@"%@", err);
    }
  }];  
}
```

A validation request looks similar, except that you have to provide data to the API methods. You can provide it in either `NSData` or `NSString` format. Please see the [API Docs](https://github.com/tidas/tidas-docs/blob/master/obj-c-client-library-api-doc.md#generating-validation-requests) for full details.

Here's a slightly modified version of the validation request from our sample Application, which signs some `NSData`:
```objective-c
- (void)validate {
  Tidas *ti = [Tidas sharedInstance];
  NSString *inputString = @"hello hello";
  __block NSString *validationData;
  NSData *stringData = [NSData dataWithBytes:[inputString UTF8String] length:[inputString length]];
  [ti generateValidationRequestForData:stringData withCompletion:^(NSString *string, NSError *err) {
    if (string){
      validationData = string;
    }
    else {
      NSLog(@"%@", err);
    }
  }];
}
```

These methods end without doing anything to the `enrollmentData` and `validationData` strings, but in your Application, you would send the output from these methods, along with a unique identifier, up to tidas-server for actually enrolling and validating the user.

_Note: Tidas uses blocks to return either successes or errors, so make sure you use a `__block` declaration on the variable you use to hold generated output._

## What's Next

That's actually it! A `Tidas::SuccessfulResult` contains the information you need to grant the user authenticated access to your Application. It is then left to developers of the Backend and Application to decide how to persist login for the user.

Please read out [Developer Guide/FAQ](https://github.com/tidas/tidas-docs/blob/master/developer-guide-faq.md) for more information about practical use cases.
