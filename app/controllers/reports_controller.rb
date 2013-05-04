require 'reporter'

class ReportsController < ApplicationController

  def report
    if params[:account_id]
      account = Account.find(params[:account_id])
      @report = Reporter.new(account, params[:password])
      @results = @report.build
    else
      @results = []
    end
  end
end
