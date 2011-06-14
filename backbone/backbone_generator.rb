require 'erb'
require 'rails/generators/rails/resource/resource_generator'

class BackboneGenerator < Rails::Generators::ResourceGenerator #metagenerator
  remove_hook_for :resource_controller
  remove_class_option :actions
  source_root File.expand_path('../templates', __FILE__)

 # argument :actions, :type => :array, :default => [], :banner => "action action"
  check_class_collision :suffix => "Controller"

  def create_controller_files
    template 'controller.rb.erb', File.join('app/controllers', class_path, "#{controller_name.underscore}_controller.rb")
  end

  def add_routes
    content = template_content 'routes.rb.erb'
    route %{#{content}}
  end

  def create_javascript_files
    create_all_directories(backbone_directories, 'public/javascripts')
    #controller
    template 'backbone_controller.js.erb', File.join('public/javascripts/controllers', class_path, "#{controller_name.underscore}_controller.js")
    #collection
    template 'backbone_collection.js.erb', File.join('public/javascripts/collections', class_path, "#{controller_name.underscore}.js")
    #model
    template 'backbone_model.js.erb', File.join('public/javascripts/models', class_path, "#{controller_name.underscore.singularize}.js")
    #views
    empty_directory File.join('public/javascripts/views', class_path, "#{controller_name.downcase.underscore}")
    template 'backbone_view_helper.js.erb', File.join("public/javascripts/views/#{controller_name.downcase.underscore}", class_path, 'helper.js')
    available_js_views.each do |view|
      template "backbone_#{view}_view.js.erb", File.join("public/javascripts/views/#{controller_name.downcase.underscore}", class_path, "#{view}.js")
    end
  end

  def create_view_files
    #TODO: can I hook in with existing template_engine but change the :format?
    empty_directory File.join('app/views', class_path, "#{controller_name.downcase.underscore}")
    available_views.each do |view|
      template "backbone_view_#{view}.jst.haml.erb", File.join("app/views/#{controller_name.downcase.underscore}", class_path, "#{view}.jst.haml")
    end
  end

  def create_jasmine_tests
    empty_directory File.join('spec', class_path, "javascripts")
    create_all_directories(backbone_directories, 'spec/javascripts')
    create_all_directories(jasmine_directories, 'spec/javascripts')
    #spec.js files
    backbone_directories.each do |type|
      filename = "#{controller_name.downcase}.spec.js" unless type == "models"
      filename = "#{file_name}.spec.js" if type == "models"
      template "backbone_#{type}.spec.js.erb", File.join("spec/javascripts/#{type}", class_path, filename)
    end
    template 'backbone_view_helper.spec.js.erb', File.join("spec/javascripts/helpers", class_path, "#{controller_name.singularize}ViewSpecHelper.js")
    #fixtures
    html_fixtures.each do |fixture|
      template "backbone.#{fixture}.fixture.html.erb", File.join("spec/javascripts/fixtures", class_path, "#{controller_name}.#{fixture}.fixture.html")
    end
    template "backbone.fixture.js.erb", File.join("spec/javascripts/fixtures", class_path, "#{controller_name}.fixture.js")
  end

  def create_rspec_controller_tests
    #hook_for :test_framework isnt' working
    template "controller_spec.rb.erb", File.join("spec/controllers", class_path, "#{controller_name.downcase}_controller_spec.rb")
  end

  def add_factory
    content = template_content 'factory.rb.erb'
    append_to_file File.join("spec", "factories.rb"), content
  end

  #hook_for :test_framework, :helper

  hook_for :assets do |assets|
    invoke assets, [controller_name]
  end


  private

  def template_content(source, &block)
      source  = File.expand_path(find_in_source_paths(source.to_s))
      context = instance_eval('binding')

      content = ERB.new(::File.binread(source), nil, '-', '@output_buffer').result(context)
      content = block.call(content) if block
      content
  end

  def backbone_directories
    %w{collections controllers models views}
  end
  def available_js_views
    %w{show edit index}
  end
  def available_views
    %w{form show collection}
  end
  def jasmine_directories
    %w{fixtures helpers support}
  end
  def html_fixtures
    %w{create_new edit_delete_links}
  end

  def create_all_directories(dirs, root_dir)
    dirs.each do |dir|
      empty_directory File.join(root_dir, class_path, dir)
    end
  end

end
