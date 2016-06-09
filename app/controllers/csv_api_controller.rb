class CsvApiController < ApplicationController
	protect_from_forgery except: :index

	def index
		unless params[:file] && File.exist?(Rails.root + "app/assets/csv/#{params[:file]}")
			render nothing: true, status: :bad_request
			return
		end

		data = File.read(Rails.root + "app/assets/csv/#{params[:file]}")
		name = File.basename(Rails.root + "app/assets/csv/#{params[:file]}", ".*")

		if params.has_key?(:callback)
			render :json => {data: data, name: name}, :callback => params[:callback]
		else
			render :json => {data: data, name: name}
		end
	end
end
