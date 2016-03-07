# Tidas Developer Guide/FAQ

iPhones with TouchID have a separate chip inside that Apple calls the Secure Enclave (SE). The SE performs crypto tasks on input while disallowing access to the sensitive data it holds.

For example, if you add a fingerprint to an iPhone, there’s no way to get that actual fingerprint data back out. You can only pass in data from another fingerprint, and ask if it matches a fingerprint inside the SE.

When you use the SE to generate a key pair, the private key is created and stored inside the SE. The key can then be used to perform encryption tasks within the SE.

Tidas uses the private key on a user’s phone by searching for it by name. The actual key data can never be seen (by us, a user, anyone!). Tidas simply asks an iPhone,

_"Dear iPhone, if there’s a private key by this name inside the Secure Enclave, can you please use it to sign this piece of data I’m providing you? Thanks so much.”_

Tidas transparently handles key management and wrapping up responses in strings which the middleware can consume. If things don’t work out (failed auth/canceled auth/etc), you’re given back an error which you can handle as you see fit.

## So how would you use it?

Here's the recommended flow for an app as we’d develop it at Trail of Bits.

### First Run
1. User on their iphone (U) requests a ‘login nonce’ from the application server (A)
2. A creates a nonce which expires after a minute and returns it to U
3. U uses the Tidas iOS SDK to create an enrollment request, signing this nonce plus any PII for signup (email, phone number, whatever we require)
4. If all goes well, Tidas iOS SDK creates an enrollment request string on U
5. U sends this to A
6. A uses the Tidas gem to request validation of the data
7. If validation succeeds, A saves the user, generates a session token and returns it to U. Otherwise, an error is returned which can be sent back to U
8. After a success, additional requests from U are sent with this session token, which serves as persistent login

### Future Logins
1. U uses the Tidas iOS SDK to create a validation request, signing any PII (like their user id) which is on the device
2. U sends this to the route on A which handles logins
3. A uses the Tidas gem to request validation of the data
4. If validation succeeds, A looks up the user via the validated data, generates a session token for that user, and returns it to U. Otherwise, an error is returned which can be sent back to U
5. After a success, additional requests from U are sent with this session token, which serves as persistent login

## Developer Scenarios

#### We have an existing app with username/password authentication. How do we replace passwords with Tidas?

Though the particulars will differ for each customer, the general idea is this:

1. Get an authenticated session for the user via normal methods
2. call `Tidas::Identity::Enroll…` to create an enrollment request string, containing data you already know about your user
3. Since you’re already logged in, send an authenticated request with the enrollment string to your backend
4. Your server should pass this request string to the tidas middleware. if the enrollment is successful, it will return a confirmation message, as well as a tidas_id (either the one you provided or one we generate)
5. Associate this tidas_id with the user in your database
6. Subsequent authentication can work as in our example above

#### What if I want to validate every request?

You can, but this could be slow for your users. [Contact us](mailto:hello@passwordlessapps.com) if you want to run a dedicated Tidas server on your own infrastructure.

#### User x gets a new phone, replacing their old one. How do we get them into our system?

Make sure you capture additional PII during user enrollment (email, phone, etc), so that you can authenticate them out of band in case they lose their device.

For example, allow users to enroll devices with an email address. If the user is already in the database, you can use an email validation loop to add them to your system. For example:

1. Existing user requests enrollment on new device through your app
	- Tidas generates generic enrollment request
	- Pass this back to the app server along with user’s email
2. Store this new enrollment in Tidas under a new tidas_id
3. Send an email asking user to verify this request
4. User opens email and verifies request
5. You can then attach this user’s information on their server to the new tidas_id
6. You can then deactivate the user’s previous tidas_id, which is now useless

Note that Tidas provides validation and authentication, but user management is ultimately up to the customer to implement.

#### What if the tidas_id I chose for a user is the key in my datastore, and I need to replace their key?

In this case you should not send an enrollment request to us until you verify this user is valid (e.g. use an email as described above).

Once the user is validated as real, send the enrollment request through the tidas middleware, including the `overwrite: true` option to replace the public key for this user.

#### User loses device, backs up to before Tidas was enabled, etc

This is the same as the above case - just validate a new enrollment request out of band.

#### User gets an additional device, which they use in parallel to their first one

Tidas identity lookups are silo’d by application and customer, but are mapped 1:1. We don’t allow one Identity to have many keys, since the unit of identity is the device.

You can set up your user database to allow multiple tidas_ids per user, (much like an ecommerce site might allow multiple credit cards), and still be able to validate data for one user with multiple devices.

#### User removes fingerprints from their device

If this happens, you need to support an additional way to validate your users, or ask them to re-add fingerprints. When fingerprints are not found, tidas will raise an error explaining this as the source of the problem
