require 'net/http'

GEOF_DEBUG = true

module Jobs
  class SendToGeof < Jobs::Base

    def self.supported_models
      #soon to come:
      #[:post, :topic, :badge, :category, :group, :invite, :post_upload, :post_action]
      #[:user, :user_action]
      [:topic, :post, :user]
    end

    def execute(opts)
      send(opts[:method], opts[:item_id])
    end

    supported_models.each do |cls|
        class_eval %{def #{cls}_create(id)
          request("/trigger/#{cls}/new",
          MultiJson.dump(
            Object.const_get("#{cls}_serializer".camelize()).new(
              Object.const_get("#{cls}".camelize()).find(id),
              scope: Guardian.new)))
        end

        def #{cls}_save(id)
          request("/trigger/#{cls}/update",
          MultiJson.dump(
            Object.const_get("#{cls}_serializer".camelize()).new(
              Object.const_get("#{cls}".camelize()).find(id),
              scope: Guardian.new)))
        end}
    end

    # FIXME: you can still do special things on specific models after
    # def post_create(post_id)
    #   post = Post.find(post_id)
    #   # soon tocome
    #   # if post.post_number == 1
    #   #   request("/topic/new",)

    #   # else
    #   request("/post/new/",
    #       MultiJson.dump(PostSerializer.new(post)))
    #   # end
    # end

    private

    def request(method, payload)
      api_key = SiteSetting.geoffrey_api_key
      address = SiteSetting.geoffrey_endpoint

      if GEOF_DEBUG and ENV.has_key? "SSH_CLIENT"
        address = "http://" + ENV["SSH_CLIENT"].split(" ")[0] + ":8091"
      end

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
    klass.after_create { _geof_perform "create"}
    klass.after_save { _geof_perform "save"}
  end

  def _geof_perform(fun)
    params = {
      :method => "#{self.class.name.demodulize.underscore}_#{fun}",
      :item_id => id
      }

    return Thread.new do
      sleep(1)
      Jobs::SendToGeof.new.perform(params)
    end if GEOF_DEBUG

    Jobs.enqueue(:send_to_geof, params)

  end
end


Jobs::SendToGeof::supported_models.each do |cls|
  Object.const_get("#{cls}".camelize).send(:include, GeoffreyObserver)
end

class Admin::GeoffreyController < Admin::AdminController
  # skip_before_filter :check_xhr, only: [:index, :config]

  def endpoint
    key = Base64.encode64 SiteSetting.geoffrey_api_key
    endpoint = "#{SiteSetting.geoffrey_endpoint}dashboard/#/login/#{key}/"
    render json: {endpoint: endpoint}
  end
end

Discourse::Application.routes.append do
  namespace :admin do
    get "geoffrey" => "geoffrey#index", constraints: AdminConstraint.new
    get "geoffrey/config" => "geoffrey#endpoint", constraints: AdminConstraint.new
  end
end

