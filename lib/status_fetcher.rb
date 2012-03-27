class StatusFetcher
  def initialize(url_retriever = UrlRetriever)
    @url_retriever = url_retriever
  end

  def fetch_all
    projects = Project.find(:all)
    projects.reject! {|project| !project.needs_poll?}
    projects.each do |project|
      retrieve_status_for(project)
      retrieve_building_status_for(project)
      project.set_next_poll!
    end
    0
  end

  def retrieve_status_for(project)
    status = ProjectStatus.new(:online => false, :success => false)
    status.error = http_errors_for(project) do
      content = @url_retriever.retrieve_content_at(project.feed_url, project.auth_username, project.auth_password)
      status = project.parse_project_status(content)
      status.online = true
    end
    project.statuses.build(status.attributes).save unless project.status.match?(status)
  end
  handle_asynchronously :retrieve_status_for, :queue => 'project_status'

  def retrieve_building_status_for(project)
    status = BuildingStatus.new(false)
    status.error = http_errors_for(project) do
      content = @url_retriever.retrieve_content_at(project.build_status_url, project.auth_username, project.auth_password)
      status = project.parse_building_status(content)
    end
    project.update_attribute(:building, status.building?)
  end
  handle_asynchronously :retrieve_building_status_for, :queue => 'build_status'

  private

  def http_errors_for(project)
    yield
    nil
  rescue URI::InvalidURIError => e
    "Invalid URI for project '#{project}': #{e.message}"
  rescue Net::HTTPError => e
    "HTTP Error retrieving status for project '#{project}': #{e.message}"
  rescue Exception => e
    "Retrieve Status failed for project '#{project}'.  Exception: '#{e.class}: #{e.message}'\n#{e.backtrace.join("\n")}"
  end
end
