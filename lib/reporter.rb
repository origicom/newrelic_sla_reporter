class Reporter

  def initialize(account, password)
    start_date = Time.now.prev_month.beginning_of_month
    end_date = start_date.end_of_month.tomorrow
    @start_date_string = start_date.strftime("%Y%m%d")
    @end_date_string = end_date.strftime("%Y%m%d")
    @hours_in_month = (end_date.yesterday.day - start_date.day + 1) * 24
    @end_date_string_in_epoch = end_date.to_i
    @api_key = account.api_key
    @username = account.username
    @password = password
    @account_id = account.account_id
    @base_uri = "https://api.newrelic.com/api/v1/accounts/#{@account_id}/applications/"
    @app_id = account.application_id
    @app_name = account.application_name
  end
 
  def build
    report_rows = []
    report_row = {}

    end_user_doc = Nokogiri::XML(get_end_user_response(@app_id).body_str)
    http_dispatcher_doc = Nokogiri::XML(get_http_dispatcher_response(@app_id).body_str)
    queue_doc = Nokogiri::XML(get_queue_response(@app_id).body_str)
    availability_doc = Nokogiri::HTML(get_availability(@app_id).body_str)

    end_user_monthly_avg = parse_field(end_user_doc)
    http_dispatcher_monthly_avg = parse_field(http_dispatcher_doc)
    queue_monthly_avg = parse_field(queue_doc)
    availability_percentage = parse_availability(availability_doc)

    app_server_monthly_avg = (http_dispatcher_monthly_avg + queue_monthly_avg) * 1000

    report_row[:app] = @app_name
    report_row[:start_date] = @start_date_string
    report_row[:end_date] = @end_date_string
    report_row[:end_user_response_time] = end_user_monthly_avg
    report_row[:app_server_response_time] = app_server_monthly_avg
    report_row[:availability] = availability_percentage
    #File.open("sla_stats_#{app}.csv", 'w') {|f| f.write(monthly_avg_str)}

    report_rows << report_row

    report_rows
  end
 
  def parse_field(doc)
    doc.xpath('//metrics/metric/field').text.to_f
  end
 
  def parse_availability(doc)
    doc.xpath("//*[@id='availability']/div[1]/div/ul/li[1]/strong").text
  end
 
  def get_end_user_response(id)
    Curl::Easy.perform("#{@base_uri}#{id}/data.xml?begin=#{@start_date_string}T04:00:00Z&end=#{@end_date_string}T04:00:00Z&&metrics[]=EndUser&field=average_response_time&summary=1") do |curl|
      curl.headers["x-api-key"] = @api_key
    end
  end
 
  def get_http_dispatcher_response(id)
    Curl::Easy.perform("#{@base_uri}#{id}/data.xml?begin=#{@start_date_string}T04:00:00Z&end=#{@end_date_string}T04:00:00Z&&metrics[]=HttpDispatcher&field=average_response_time&summary=1") do |curl|
      curl.headers["x-api-key"] = @api_key
    end
  end
 
  def get_queue_response(id)
    Curl::Easy.perform("#{@base_uri}#{id}/data.xml?begin=#{@start_date_string}T04:00:00Z&end=#{@end_date_string}T04:00:00Z&&metrics[]=WebFrontend/QueueTime&field=average_response_time&summary=1") do |curl|
      curl.headers["x-api-key"] = @api_key
    end
  end
 
  def get_availability(id)
    availability = Curl::Easy.new("https://rpm.newrelic.com/accounts/#{@account_id}/applications/#{id}/downtime?ctw=custom&tw[dur]=#{@hours_in_month}&tw[end]=#{@end_date_string_in_epoch}") do |curl|
      curl.http_auth_types = :basic
      curl.username = @username
      curl.password = @password
      curl.perform
    end
    availability
  end
end
