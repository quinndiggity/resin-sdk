errors = require('resin-errors')
semver = require('semver')
cloneDeep = require('lodash/cloneDeep')
fromPairs = require('lodash/fromPairs')
isArray = require('lodash/isArray')
isFunction = require('lodash/isFunction')
isNumber = require('lodash/isNumber')
isString = require('lodash/isString')

exports.deviceTypes = require('./device-types')
exports.getImgMakerHelper = require('./img-maker')

exports.notImplemented = notImplemented = ->
	throw new Error('The method is not implemented.')

exports.onlyIf = (condition) -> (fn) -> if condition then fn else notImplemented

exports.isId = isNumber

# Use with: `findCallback(arguments)`.
exports.findCallback = (args) ->
	lastArg = args[args.length - 1]
	if isFunction(lastArg)
		return lastArg
	return null

exports.notFoundResponse =
	code: 'ResinRequestError'
	statusCode: 404

exports.treatAsMissingApplication = (nameOrId) ->
	return (err) ->
		replacementErr = new errors.ResinApplicationNotFound(nameOrId)
		replacementErr.stack = err.stack
		throw replacementErr

exports.treatAsMissingDevice = (uuidOrId) ->
	return (err) ->
		replacementErr = new errors.ResinDeviceNotFound(uuidOrId)
		replacementErr.stack = err.stack
		throw replacementErr

safeSemver = (version) ->
	version.replace(/(\.[0-9]+)\.rev/, '$1+rev')

exports.osVersionRCompare = (versionA, versionB) ->
	versionA = safeSemver(versionA)
	versionB = safeSemver(versionB)
	semverResult = semver.rcompare(versionA, versionB)
	if semverResult != 0
		return semverResult

	revA = getRev(versionA)
	revB = getRev(versionB)

	if revA isnt revB
		return revB - revA

	devA = exports.isDevelopmentVersion(versionA)
	devB = exports.isDevelopmentVersion(versionB)
	if devA isnt devB
		return devA - devB

	return versionA.localeCompare(versionB)

exports.isDevelopmentVersion = (version) ->
	/(\.|\+|-)dev/.test(version)

getRev = (osVersion) ->
	rev = semver.parse(osVersion).build
	.map((metadataPart) -> /rev(\d+)/.exec(metadataPart)?[1])
	.filter((x) -> x?)[0]

	if rev?
		parseInt(rev, 10)
	else
		0

# Merging two sets of pine options sensibly is more complicated than it sounds.
#
# The general rules are:
# * select, orderby, top and skip override (select this, instead of the default)
# * filters are combined (i.e. both filters must match)
# * expands are combined (include both expansions), and this recurses down.
#   * That means $expands within expands are combined
#   * And $selects within expands override
# * Any unknown 'extra' options throw an error. Unknown 'default' options are ignored.
exports.mergePineOptions = (defaults, extras) ->
	if not extras
		return defaults

	result = cloneDeep(defaults)

	for own option, value of extras
		switch option
			when 'select', 'orderby', 'top', 'skip'
				result[option] = value

			when 'filter'
				if defaults.filter
					result.filter = $and: [ defaults.filter, value ]
				else
					result.filter = value

			when 'expand'
				result.expand = mergeExpandOptions(defaults.expand, value)

			else
				throw new Error("Unknown pine option: #{option}")

	return result

mergeExpandOptions = (defaultExpand, extraExpand) ->
	if not defaultExpand? then return extraExpand

	defaultExpand = convertExpandToObject(defaultExpand)
	extraExpand = convertExpandToObject(extraExpand)

	for own expandKey, extraExpandOptions of extraExpand
		expandOptions = defaultExpand[expandKey] ||= {}

		if extraExpandOptions.$select
			expandOptions.$select = extraExpandOptions.$select

		if extraExpandOptions.$expand
			expandOptions.$expand = mergeExpandOptions(expandOptions.$expand, extraExpandOptions.$expand)

	return defaultExpand

# Converts a valid expand object in any format into a new object
# containing (at most) a $expand and a $select key
convertExpandToObject = (expandOption) ->
	if not expandOption?
		return {}
	else if isString(expandOption)
		return "#{expandOption}": {}
	else if isArray(expandOption)
		return fromPairs(expandOption.map((key) -> [key, {}]))
	else
		# Check the options in this object are the ones we know how to merge
		for own expandKey, expandRelationshipOptions of expandOption
			invalidKeys = Object.keys(expandRelationshipOptions).filter (key) ->
				key != '$select' and key != '$expand'
			if invalidKeys.length > 0
				throw new Error("Unknown pine expand options: #{invalidKeys}")

		return cloneDeep(expandOption)
