require 'reporter'

class ReportsController < ApplicationController

  def report
    if params[:account_id]
      account = Account.find(params[:account_id])
      @report = Reporter.new(account, params[:password])
      @results = @report.build
      respond_to do |format|
        format.html
        format.csv { send_data generate_csv(@results) }
      end
    else
      @results = []
    end
  end

private

  def generate_csv(results)
    results = results.first
    CSV.generate do |csv|
      csv << ["App name","Start date","End date","End user avg response time (s)","App server avg response time (ms)","Availability %"]
      csv << [results[:app],results[:start_date],results[:end_date],results[:end_user_response_time],results[:app_server_response_time],results[:availability]]
    end
  end
end
