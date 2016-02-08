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
