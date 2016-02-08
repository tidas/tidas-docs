# Obj-C Client Library API Doc

## Background
This SDK contains the methods needed to pack data from a user's device into a format which the Tidas server can consume. Objects consumable by the Tidas middleware and server are strings called TidasBlobs. TidasBlobs contain the following data:

	- Platform (iOS only for now)
	- Your App Data (Optional)
	- Timestamp
	- SHA256 Hash of Your App Data and the Timestamp
	- Cryptographic Signature of the Hash
	- User's Public Key Data (Optional)

The data is signed with a key pair which Tidas transparently creates when first instantiated. Successful creation of this key pair relies on TouchID being enabled, with fingerprints saved to the user's device.

## API v1.0

### Generating Enrollment Requests

This call is used to generate enrollment request TidasBlob strings. Once your enrollment request TidasBlob string is created, you can send it to a backend endpoint which has the Tidas middleware enabled to continue the authentication process.

**Generate an enrollment request:**

```objective-c
- (void) generateEnrollmentRequestWithCompletion:(void (^)(NSString *string, NSError *err))completion;
```

This call takes no input string or data. It signs the hash of a timestamp and packages a tidas blob for you.

Parameters:

* **None**

Example Usage:

```objective-c	
Tidas *ti = [Tidas sharedInstance];
__block NSString *enrollmentData;
[ti generateEnrollmentRequestWithCompletion:^(NSString *string, NSError *err) {
  if (string) {
	enrollmentData = string;
  }
  else{
    NSLog(@"Err: %@", err);
  }
}];
// Send the enrollmentData object to your server for further processing if it holds data
```

### Generating Validation Requests

These calls are used to generate TidasBlob strings for validation. We expose the main method and one convenience method for implementers to use as needed.

Once your TidasBlob string is created, you can send it to a backend endpoint which has the Tidas middleware enabled to continue the authentication process.

TidasBlob validation strings must be created with input data. Upon successful signature validation by the Tidas server, this input data is provided back to you on your backend.

**Generate a validation request which signs input data:**

```objective-c
- (void) generateValidationRequestForData:(NSData *)data withCompletion:(void(^) (NSString *string, NSError *err))completion;
```

This version of the signing method takes input data, signs the hash of your input data and a timestamp and returns a TidasBlob string to you.

Parameters:

* **data:** \<NSData> from either your user's device or your backend

Example Usage:
```objective-c
Tidas *ti = [Tidas sharedInstance];
NSData *inputData = [NSData dataWithBytes:<bytes>];
__block NSString *validationData;
[ti generateValidationRequestForData:inputData withCompletion:^(NSString *string, NSError *err) {
  if (string){
	validationData = string;
  }
  else {
    NSLog(@"Err: %@", err);
  }
}];
// Send the validationData object to your server for further processing if it holds data
```

**Generate a validation request which signs an input string:**

```objective-c
- (void) signAndBoxString:(NSString *)string completion:(void(^) (NSString *dataString, NSError *err))completion;
```

This version of the signing method is a vanity method which wraps the previous method, allowing implementers to pass in a string instead of data.

Parameters:

* **string:** \<NSString> from either your user's device or your backend

Example Usage:
```objective-c
Tidas *ti = [Tidas sharedInstance];
NSString *inputString = @"testtest";
__block NSString *validationData;
[ti signAndBoxString:inputString completion:^(NSString *dataString, NSError *err) {
  if (dataString){
	validationData = dataString;
  }
  else {
    NSLog(@"Err: %@", err);
  }
}];
// Send the validationData object to your server for further processing if it holds data
```

### Abandoning ship (Revoke and Regenerate Keys)

```objective-c
- (void) resetKeychain;
```

If for some reason you need to clear the keys and certificate created by Tidas, this method can be invoked to create a new pair of keys. After this is called, no subsequent calls to validate data with the public key stored on Tidas' server will succeed.

You will need to send a new enrollment request from the user's device before validating any information. If you wish to connect this new enrollment to the `tidas_id` which the previous public key was associated with, the Tidas Middleware API supports an `overwrite` option which you can use when sending the enrollment request to the Tidas server from your backend.

Parameters:

* **None**

Example Usage:

```objective-c	
Tidas *ti = [Tidas sharedInstance];
[ti resetKeychain];
//[ti generateEnrollmentRequestWithString.......]
// do whatever it is that needs doing
```

## Tidas Error Statuses

List of Errors which may be encountered when using the Tidas iOS SDK

- **errTidasSuccess** 
  - Code: 0
  - Description: Successful result
- **errNoTouchID**
  - Code: 1
  - Description: TouchID not available on the device, due to either no fingerprints saved, or no fingerprint sensor
- **errBadData**
  - Code: 2
  - Description: No data was provided when attempting to make a validation request
- **errUserCancelled**
  - Code: 3
  - Description: User cancelled TouchID authorization
- **errNotAuthorized**
  - Code: 4
  - Description: User failed TouchID authorization
- **errTidasException**
  - Code: 5
  - Description: Uncaught runtime error - if you see this, please report it to us!
