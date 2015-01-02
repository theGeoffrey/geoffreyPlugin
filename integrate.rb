require 'net/http'


module Jobs
	class SendToGeof < Jobs::Base

		def self.supported_models
			#soon to come:
			#[:badge, :category, :group, :invite, :post_upload, :post_action]
			[:user, :user_action]
		end

		def execute(method, item_id)
			send(method, item_id)
		end

		supported_models.each do |cls|
		    class_eval %{def #{cls}_create(id)
		    	request("/#{cls}/new/",
					MultiJson.dump(
						Object.const_get("#{cls}_serializer".camelize()).new(
							Object.const_get("#{cls}".camelize()).find(id))))
		    end}
		    class_eval %{def #{cls}_save(id)
		    	request("/#{cls}/update/",
					MultiJson.dump(
						Object.const_get("#{cls}_serializer".camelize()).new(
							Object.const_get("#{cls}".camelize()).find(id))))
		    end}
		end

		def post_create(post_id)
			post = Post.find(post_id)
			# soon tocome
			# if post.post_number == 1
			# 	request("/topic/new",)

			# else
			request("/post/new/",
					MultiJson.dump(PostSerializer.new(post)))
			# end
		end

		private

		def request(method, payload)
			api_key = SiteSettings.geoffrey_api_key
			address = SiteSettings.geoffrey_endpoint

			# FIXME: add HTTPS support!
			uri = URI.parse("#{address}/api#{method}?key=#{api_key}")
			http = Net::HTTP.new(uri.host, uri.port)
			request = Net::HTTP::Post.new(uri.request_uri)
			response = http.request(request, payload)
			json = JSON.parse(response.body)

			if json["succeed"] != true
				raise "Failed to Geoffrey #{json}"
			end
		end
	end
end


module GeoffreyObserver

	def self.included(klass)
		klass.after_create :_geof_create
		klass.after_save :_geof_save
	end

	def _geof_create
		geof = Jobs::SendToGeof.new
		geof.perform('#{name}_create', id)

		#Jobs.enqueue(:send_to_geof, '#{name}_create', id)
	end

	def _geof_save
		geof = Jobs::SendToGeof.new
		geof.perform('#{name}_save', id)
		#Jobs.enqueue(:send_to_geof, '#{name}_save', id)
	end
end


# Jobs::SendToGeof::supported_models.each do |cls|
# 	Object.const_get("#{cls}".camelize).send(:include, GeoffreyObserver)
# end

