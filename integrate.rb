require 'net/http'

module Jobs
	class SendToGeof < Jobs::Base

		def initialize
		end

		def execute(args)
			api_key = SiteSettings.geoffrey_api_key
			address = SiteSettings.geoffrey_target_domain

			method = args['method']

			uri = URI.parse("http://#{address}/api#{method}?key=#{api_key}")
			http = Net::HTTP.new(uri.host, uri.port)
			request = Net::HTTP::Post.new(uri.request_uri)
			response = http.request(request, JSON.dump(args))
			json = JSON.parse(response.body)

			if json["succeed"] != true
				raise "Failed to post new user to Geoffrey"
			end
		end
	end
end



module GeoffreyPluginUser

	def self.included(klass)
		klass.after_create :add_user_geof
	end

	def add_user_geof
		method = '/users/new'
		Jobs.enqueue(:send_to_geof, email: email, user: id, method: method)
		
	end
end

module GeoffreyPluginPost

	def self.included(klass)
		klass.after_create :add_post_geof
	end

	def add_post_geof
		method = '/posts/new'
		Jobs.enqueue(:send_to_geof, post: id, method: method)
		
	end
end

User.send :include, GeoffreyPluginUser
Post.send :include, GeoffreyPluginPost
