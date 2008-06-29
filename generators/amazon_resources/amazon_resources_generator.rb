class AmazonResourcesGenerator < Rails::Generator::NamedBase
  attr_reader :access_key, :associate_tag

  def initialize(runtime_args, runtime_options = {})
    super

    @access_key, @associate_tag = runtime_args[1..-1] 
    @access_key ||= 'UnDefinedAccessKeyID'
    @associate_tag ||= 'kaeruspoon-22'
  end

  def manifest
    record do |m|
      m.class_collisions class_path, "#{class_name}"

      # Controller, helper, views, and test directories.
      m.directory File.join('app/models', class_path)

      m.template 'model.rb',
                  File.join('app/models',
                            class_path,
                            "#{file_name}.rb")

      unless options[:skip_migration]
        m.migration_template 'migration.rb', 'db/migrate', :assigns => {
          :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}"
        }, :migration_file_name => "create_#{file_path.gsub(/\//, '_').pluralize}"
      end
    end
  end

  protected
    def banner
      "Usage: #{$0} amazon_resources ModelName AccessKeyID AssociateTag"
    end
end
