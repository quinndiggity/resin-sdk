_ = require('lodash')
m = require('mochainon')

{ resin, givenLoggedInUser, credentials } = require('../setup')

describe 'Application Model', ->

	givenLoggedInUser()

	describe 'given no applications', ->

		describe 'resin.models.application.getAll()', ->

			it 'should eventually become an empty array', ->
				promise = resin.models.application.getAll()
				m.chai.expect(promise).to.become([])

		describe 'resin.models.application.hasAny()', ->

			it 'should eventually be false', ->
				promise = resin.models.application.hasAny()
				m.chai.expect(promise).to.eventually.be.false

		describe 'resin.models.application.create()', ->

			it 'should be able to create an application', ->
				resin.models.application.create('FooBar', 'raspberry-pi').then ->
					promise = resin.models.application.getAll()
					m.chai.expect(promise).to.eventually.have.length(1)

			it 'should be able to create a child application', ->
				resin.models.application.create('FooBar', 'raspberry-pi').then (parentApplication) ->
					resin.models.application.create('FooBarChild', 'edge', parentApplication.id)
				.then ->
					resin.models.application.getAll()
				.then ([ parentApplication, childApplication ]) ->
					m.chai.expect(childApplication.application.__id).to.equal(parentApplication.id)

			it 'should be rejected if the device type is invalid', ->
				promise = resin.models.application.create('FooBar', 'foobarbaz')
				m.chai.expect(promise).to.be.rejectedWith('Invalid device type: foobarbaz')

			it 'should be rejected if the name has less than three characters', ->
				promise = resin.models.application.create('Fo', 'raspberry-pi')
				m.chai.expect(promise).to.be.rejectedWith('It is necessary that each app name that is of a user (Auth), has a Length (Type) that is greater than or equal to 4.')

			it 'should be able to create an application using a device type alias', ->
				resin.models.application.create('FooBar', 'raspberrypi').then ->
					promise = resin.models.application.getAll()
					m.chai.expect(promise).to.eventually.have.length(1)

	describe 'given a single application', ->

		beforeEach ->
			resin.models.application.create('FooBar', 'raspberry-pi').then (application) =>
				@application = application

		describe 'resin.models.application.hasAny()', ->

			it 'should eventually be true', ->
				promise = resin.models.application.hasAny()
				m.chai.expect(promise).to.eventually.be.true

		describe 'resin.models.application.create()', ->

			it 'should reject if trying to create an app with the same name', ->
				promise = resin.models.application.create('FooBar', 'beaglebone-black')
				m.chai.expect(promise).to.be.rejectedWith('Application name must be unique')

		describe 'resin.models.application.hasAny()', ->

			it 'should eventually be true', ->
				promise = resin.models.application.hasAny()
				m.chai.expect(promise).to.eventually.be.true

		describe 'resin.models.application.getAll()', ->

			it 'should return an array with length 1', ->
				promise = resin.models.application.getAll()
				m.chai.expect(promise).to.eventually.have.length(1)

			it 'should eventually become an array containing the application', ->
				resin.models.application.getAll().then (applications) =>
					m.chai.expect(applications[0].id).to.equal(@application.id)

			it 'should add a devices_length property', ->
				resin.models.application.getAll().then (applications) ->
					m.chai.expect(applications[0].devices_length).to.equal(0)

			it 'should add an online_devices property', ->
				resin.models.application.getAll().then (applications) ->
					m.chai.expect(applications[0].online_devices).to.equal(0)

			it 'should support arbitrary pinejs options', ->
				resin.models.application.getAll(expand: 'user')
				.then (applications) ->
					m.chai.expect(applications[0].user[0].username).to.equal(credentials.username)

		describe 'resin.models.application.get()', ->

			it 'should be able to get an application by name', ->
				promise = resin.models.application.get(@application.app_name)
				m.chai.expect(promise).to.become(@application)

			it 'should be able to get an application by id', ->
				promise = resin.models.application.get(@application.id)
				m.chai.expect(promise).to.become(@application)

			it 'should be rejected if the application name does not exist', ->
				promise = resin.models.application.get('HelloWorldApp')
				m.chai.expect(promise).to.be.rejectedWith('Application not found: HelloWorldApp')

			it 'should be rejected if the application id does not exist', ->
				promise = resin.models.application.get(999999)
				m.chai.expect(promise).to.be.rejectedWith('Application not found: 999999')

			it 'should support arbitrary pinejs options', ->
				resin.models.application.get(@application.id, expand: 'user')
				.then (application) ->
					m.chai.expect(application.user[0].username).to.equal(credentials.username)

		describe 'resin.models.application.getById()', ->

			it 'should be able to get an application', ->
				promise = resin.models.application.getById(@application.id)
				m.chai.expect(promise).to.become(@application)

			it 'should be rejected if the application does not exist', ->
				promise = resin.models.application.getById(999999)
				m.chai.expect(promise).to.be.rejectedWith('Application not found: 999999')

		describe 'resin.models.application.has()', ->

			it 'should eventually be true if the application name exists', ->
				promise = resin.models.application.has(@application.app_name)
				m.chai.expect(promise).to.eventually.be.true

			it 'should eventually be true if the application id exists', ->
				promise = resin.models.application.has(@application.id)
				m.chai.expect(promise).to.eventually.be.true

			it 'should return false if the application id is undefined', ->
				promise = resin.models.application.has(undefined)
				m.chai.expect(promise).to.eventually.be.false

			it 'should eventually be false if the application name does not exist', ->
				promise = resin.models.application.has('HelloWorldApp')
				m.chai.expect(promise).to.eventually.be.false

			it 'should eventually be false if the application id does not exist', ->
				promise = resin.models.application.has(999999)
				m.chai.expect(promise).to.eventually.be.false

		describe 'resin.models.application.remove()', ->

			it 'should be able to remove an existing application by name', ->
				resin.models.application.remove(@application.app_name).then ->
					promise = resin.models.application.getAll()
					m.chai.expect(promise).to.eventually.have.length(0)

			it 'should be able to remove an existing application by id', ->
				resin.models.application.remove(@application.id).then ->
					promise = resin.models.application.getAll()
					m.chai.expect(promise).to.eventually.have.length(0)

			it 'should be rejected if the application name does not exist', ->
				promise = resin.models.application.remove('HelloWorldApp')
				m.chai.expect(promise).to.be.rejectedWith('Application not found: HelloWorldApp')

			it 'should be rejected if the application id does not exist', ->
				promise = resin.models.application.remove(999999)
				m.chai.expect(promise).to.be.rejectedWith('Application not found: 999999')

		describe 'resin.models.application.getApiKey()', ->

			it 'should be able to generate an API key by name', ->
				resin.models.application.getApiKey(@application.app_name).then (apiKey) ->
					m.chai.expect(_.isString(apiKey)).to.be.true
					m.chai.expect(apiKey).to.have.length(32)

			it 'should be able to generate an API key by id', ->
				resin.models.application.getApiKey(@application.id).then (apiKey) ->
					m.chai.expect(_.isString(apiKey)).to.be.true
					m.chai.expect(apiKey).to.have.length(32)

			it 'should be rejected if the application name does not exist', ->
				promise = resin.models.application.getApiKey('HelloWorldApp')
				m.chai.expect(promise).to.be.rejectedWith('Application not found: HelloWorldApp')

			it 'should be rejected if the application id does not exist', ->
				promise = resin.models.application.getApiKey(999999)
				m.chai.expect(promise).to.be.rejectedWith('Application not found: 999999')
