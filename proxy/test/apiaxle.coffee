# always run as test
process.env.NODE_ENV = "test"

_ = require "underscore"

{ ApiaxleProxy } = require "../apiaxle_proxy"
{ AppTest } = require "apiaxle.base"

{ GetCatchall } = require "../app/controller/catchall_controller"

class exports.ApiaxleTest extends AppTest
  @appClass = ApiaxleProxy

  stubCatchall: ( status, body, headers={} ) ->
    # stub out the http request in the controller that we do
    @getStub GetCatchall::, "_httpRequest", ( options, api, key, cb ) =>
      @fakeIncomingMessage status, body, headers, ( err, res ) =>
        return cb err, res, body

  newApiAndKey: ( api, apiOptions, key, keyOptions={}, cb ) ->
    # make sure there's an endpoint
    apiOptions = _.extend apiOptions,
      endPoint: "graph.facebook.com"

    @application.model( "api" ).create api, apiOptions, ( err, newApi ) =>
      return cb err if err

      keyOptions["forApi"] = api

      @application.model( "key" ).create key, keyOptions, ( err, newKey ) =>
        return cb err if err

        return cb null, newApi, newKey
