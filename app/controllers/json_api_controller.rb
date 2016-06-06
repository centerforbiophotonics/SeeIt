class JsonApiController < ApplicationController
	protect_from_forgery except: :index

	def index
		print params[:file]
		unless params[:file] && File.exist?(Rails.root + "app/assets/json/#{params[:file]}")
			print "File not found"
			render nothing: true, status: :bad_request
			return
		end

		data = File.read(Rails.root + "app/assets/json/#{params[:file]}")
		
		if params.has_key?(:callback)
			render :json => JSON.parse(data), :callback => params[:callback]
		else
			render :json => JSON.parse(data)
		end
	end
end
