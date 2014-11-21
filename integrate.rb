module Jobs
	class SendUserGeof < Jobs::Base

		def execute
			uri = URI.parse("http://geoffrey.co/users/add")
			request = Net::HTTP::Post.new(uri.request_uri)
			request.set_form_data("key" => "yay", "email" => email)
			response = http.request(request)
			json = JSON.parse(response.body)

			if json["succeed"] != true
				raise "Failed to post new user to Geoffrey"
			end
		end
	end
end

module GeoffreyPlugin

	def self.included(klass)
		klass.after_create :add_user_geof
	end

	def add_user_geof
		Jobs.enqueue(:send_user_geof)
		
	end
end

User.send :include, GeoffreyPlugin
