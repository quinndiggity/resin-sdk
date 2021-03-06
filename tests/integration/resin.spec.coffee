m = require('mochainon')

{ resin, getSdk, sdkOpts, credentials } = require('./setup')

describe 'Resin SDK', ->

	describe 'factory function', ->

		validKeys = ['auth', 'models', 'logs', 'settings']

		describe 'given no opts', ->

			it 'should return an object with valid keys', ->
				mockResin = getSdk()
				m.chai.expect(mockResin).to.include.keys(validKeys)

		describe 'given empty opts', ->

			it 'should return an object with valid keys', ->
				mockResin = getSdk({})
				m.chai.expect(mockResin).to.include.keys(validKeys)

		describe 'given opts', ->

			it 'should return an object with valid keys', ->
				mockResin = getSdk(sdkOpts)
				m.chai.expect(mockResin).to.include.keys(validKeys)

	describe 'interception Hooks', ->

		beforeEach ->
			resin.interceptors = []

		afterEach ->
			resin.interceptors = []

		it "should update if the array is set directly (not only if it's mutated)", ->
			interceptor = request: m.sinon.mock().returnsArg(0)
			resin.interceptors = [ interceptor ]

			resin.models.application.getAll().then ->
				m.chai.expect(interceptor.request.called).to.equal true,
					'Interceptor set directly should have its request hook called'

		describe 'for request', ->
			it 'should be able to intercept requests', ->
				resin.interceptors.push request: m.sinon.mock().returnsArg(0)

				promise = resin.models.application.getAll()

				promise.then ->
					m.chai.expect(resin.interceptors[0].request.called).to.equal true,
						'Interceptor request hook should be called'

		describe 'for requestError', ->
			it 'should intercept request errors from other interceptors', ->
				resin.interceptors.push request:
					m.sinon.mock().throws(new Error('rejected'))
				resin.interceptors.push requestError:
					m.sinon.mock().throws(new Error('replacement error'))

				promise = resin.models.application.getAll()

				m.chai.expect(promise).to.be.rejectedWith('replacement error')
				.then ->
					m.chai.expect(resin.interceptors[1].requestError.called).to.equal true,
						'Interceptor requestError hook should be called'

		describe 'for response', ->
			it 'should be able to intercept responses', ->
				resin.interceptors.push response: m.sinon.mock().returnsArg(0)

				promise = resin.models.application.getAll()

				promise.then ->
					m.chai.expect(resin.interceptors[0].response.called).to.equal true,
						'Interceptor response hook should be called'

		describe 'for responseError', ->
			it 'should be able to intercept error responses', ->
				called = false
				resin.interceptors.push responseError: (err) ->
					called = true
					throw err

				promise = resin.auth.authenticate
					email: 'helloworld@resin.io',
					password: 'asdfghjkl'

				m.chai.expect(promise).to.be.rejectedWith('Request error: Unauthorized')
				.then ->
					m.chai.expect(called).to.equal true,
						'responseError should be called when authentication fails'

