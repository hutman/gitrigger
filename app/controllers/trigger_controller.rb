class TriggerController < ApplicationController
  unloadable

  GIT_BIN = Redmine::Configuration['scm_git_command'] || "git"
  skip_before_filter :verify_authenticity_token, :check_if_login_required
  before_filter :validate_project


  def validate_project
    begin
      @project = Project.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404 and return false
    end
  end


  def index
      repositories = find_repositories

      repositories.each do |repository|
        # Fetch the changes from Github
        update_repository(repository)

        # Fetch the new changesets into Redmine
        repository.fetch_changesets
      end

    render(:text => 'OK')
  end

  def welcome
    # Render the default layout
  end

  private

  def system(command)
    Kernel.system(command)
  end

  # Executes shell command. Returns true if the shell command exits with a success status code
  def exec(command)
    logger.debug { "GithubHook: Executing command: '#{command}'" }

    # Get a path to a temp file
    logfile = Tempfile.new('github_hook_exec')
    logfile.close

    success = system("#{command} > #{logfile.path} 2>&1")
    output_from_command = File.readlines(logfile.path)
    if success
      logger.debug { "GithubHook: Command output: #{output_from_command.inspect}"}
    else
      logger.error { "GithubHook: Command '#{command}' didn't exit properly. Full output: #{output_from_command.inspect}"}
    end

    return success
  ensure
    logfile.unlink
  end

  def git_command(command, repository)
    GIT_BIN + " --git-dir='#{repository.url}' #{command}"
  end

  # Fetches updates from the remote repository
  def update_repository(repository)
    command = git_command('remote update', repository)
    if exec(command)
      #command = git_command("fetch origin '+refs/heads/*:refs/heads/*'", repository)
      command = git_command("remote update", repository)
      exec(command)
    end
  end

  # Finds the Redmine project in the database based on the given project identifier
  def find_project
    project = Project.find(params[:id])
    raise ActiveRecord::RecordNotFound, "No project found with identifier '#{identifier}'" if project.nil?
    return project
  end

  # Returns the Redmine Repository object we are trying to update
  def find_repositories
    project = find_project
    repositories = project.repositories.select do |repo|
      repo.is_a?(Repository::Git)
    end

    if repositories.nil? or repositories.length == 0
      raise TypeError, "Project '#{project.to_s}' ('#{project.identifier}') has no repository"
    end

    return repositories
  end

end
