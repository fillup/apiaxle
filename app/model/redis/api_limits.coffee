async = require "async"

{ QpsExceededError, QpdExceededError } = require "../../../lib/error"
{ Redis } = require "../redis"

class exports.ApiLimits extends Redis
  @instantiateOnStartup = true

  # Where `limits` might contain:
  # * qps - queries per second
  # * qpd - queries per day
  withinLimits: ( user, apiKey, limits, cb ) ->
    checks = [ ]

    checks.push ( cb ) =>
      @withinQps user, apiKey, limits.qps, cb

    checks.push ( cb ) =>
      @withinQpd user, apiKey, limits.qpd, cb

    async.series checks, ( err, [ remainingQps, remainingQpd ] ) ->
      return cb err if err

      return cb null,
        remainingQps: remainingQps
        remainingQpd: remainingQpd

  withinQps: ( user, apiKey, qps, cb ) ->
    @_withinLimit @qpsKey( user, apiKey ), 1, qps, QpsExceededError, cb

  withinQpd: ( user, apiKey, qpd, cb ) ->
    @_withinLimit @qpdKey( user, apiKey ), 86000, qpd, QpdExceededError, cb

  qpsKey: ( user, apiKey ) ->
    return [ "qps", user, apiKey ]

  qpdKey: ( user, apiKey ) ->
    return [ "qpd", @_dayString(), user, apiKey ]

  _setInitialQp: ( key, qp, expires, cb ) ->
    @set [ key ], qp, ( err, res ) =>
      return cb err if err

      # expires in a second
      @expire [ key ], expires, ( err, result ) =>
        return cb err if err

        return cb null, qp

  _withinLimit: ( key, expires, qpLimit, exceedErrorClass, cb ) ->
    # join the key here to save cycles
    key = key.join ":"

    # how many calls have we got left (if any)?
    @get [ key ], ( err, callsLeft ) =>
      return cb err if err

      # no key set yet (or it expired)
      if not callsLeft?
        return @_setInitialQp key, qpLimit, expires, cb

      # no more calls left
      if callsLeft <= 0
        return cb new exceedErrorClass "#{ qpLimit} allowed."

      return cb null, callsLeft
