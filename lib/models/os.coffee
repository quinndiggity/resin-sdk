###
Copyright 2016 Resin.io

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
###

url = require('url')
request = require('resin-request')
settings = require('resin-settings-client')

###*
# @summary Download an OS image
# @name download
# @public
# @function
# @memberof resin.models.os
#
# @param {String} deviceType - device type slug
# @fulfil {ReadableStream} - download stream
# @returns {Promise}
#
# @example
# resin.models.os.download('raspberry-pi').then(function(stream) {
# 	stream.pipe(fs.createWriteStream('foo/bar/image.img'));
# });
#
# resin.models.os.download('raspberry-pi', function(error, stream) {
# 	if (error) throw error;
# 	stream.pipe(fs.createWriteStream('foo/bar/image.img'));
# });
###
exports.download = (deviceType, callback) ->
	imageMakerUrl = settings.get('imageMakerUrl')

	request.stream
		method: 'GET'
		url: url.resolve(imageMakerUrl, "/api/v1/image/#{deviceType}/")
	.nodeify(callback)
