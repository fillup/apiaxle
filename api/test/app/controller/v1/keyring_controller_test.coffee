_     = require "underscore"
async = require "async"

{ ApiaxleTest } = require "../../../apiaxle"

class exports.KeyringControllerTest extends ApiaxleTest
  @start_webserver = true
  @empty_db_on_setup = true

  "test GET a valid keyring": ( done ) ->
    # now try and get it
    @GET path: "/v1/keyring/1234", ( err, res ) =>
      @isNull err
      res.parseJson ( json ) =>
        @ok 1

        done 2

  "test GET a list of keyrings": ( done ) ->
    all_keyrings = []

    for i in [ 1..15 ]
      all_keyrings.push @fixtures.createKeyring

    async.series all_keyrings, ( err, keyrings ) =>
      @isNull err

      @GET path: "/v1/keyrings?from=2&to=4", ( err, res ) =>
        res.parseJson ( json ) =>
          @deepEqual json.results, _.pluck( keyrings[2..4], "id" )

          done 2

  "test GET keys for a valid keyring": ( done ) ->
    @fixtures.createApi "twitter", ( err ) =>
      @fixtures.createKeyring "blah", ( err, keyring ) =>
        new_keys = []

        # create a bunch of keys
        for i in [ 1..15 ]
          new_keys.push ( cb ) =>
            @fixtures.createKey ( err, key ) =>
              keyring.addKey key.id, cb

        async.series new_keys, ( err, keys ) =>
          @isNull err

          @GET path: "/v1/keyring/blah/keys?from=0&to=9", ( err, res ) =>
            @isNull err
            res.parseJson ( json ) =>
              @equal json.results.length, 10
              @deepEqual json.results, _.pluck( keys[ 0..9 ], "id")

              done 4

  "test GET a non-existant keyring": ( done ) ->
    # now try and get it
    @GET path: "/v1/keyring/1234", ( err, res ) =>
      @isNull err
      @equal res.statusCode, 404

      res.parseJson ( json ) =>
        @ok json.results.error
        @equal json.results.error.type, "KeyringNotFoundError"

        done 4

  "test GET a non-existant keyring": ( done ) ->
    # now try and get it
    @GET path: "/v1/keyring/1234", ( err, res ) =>
      @isNull err
      @equal res.statusCode, 404

      res.parseJson ( json ) =>
        @ok json.results.error
        @equal json.results.error.type, "KeyringNotFoundError"

        done 4

  "test POSTing a valid key to a valid keyring": ( done ) ->
    fixture =
      api:
        twitter: {}
      key:
        1234: {}
        5678: {}
      keyring:
        ring1: {}
        ring2: {}

    @fixtures.create fixture, ( err ) =>
      @isNull err

      model = @application.model( "keyringFactory" )
      model.find "ring1", ( err, keyring ) =>
        @isNull err
        @ok keyring
        @equal keyring.id, "ring1"

        add_key_functions = []
        add_key_functions.push ( cb ) =>
          @POST path: "/v1/keyring/ring1/key/1234", ( err, res ) =>
            @isNull err
            res.parseJson ( json ) =>
              @equal json.results, true

              # get all of the keys, check there's just one
              keyring.getKeys 0, 100, ( err, keys ) =>
                @deepEqual keys, [ "1234" ]

                cb()

        add_key_functions.push ( cb ) =>
          @POST path: "/v1/keyring/ring1/key/5678", ( err, res ) =>
            @isNull err
            res.parseJson ( json ) =>
              @equal json.results, true

              # get all of the keys, check there's just one
              keyring.getKeys 0, 100, ( err, keys ) =>
                @deepEqual keys, [ "5678", "1234" ]

                cb()

        async.series add_key_functions, ( err ) =>
          @isNull err

          done 11