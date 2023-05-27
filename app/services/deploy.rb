class Deploy
  def initialize(client: Aws::S3::Client.new(region: 'us-east-1'))
    @client = client
  end

  def deploy_site(bucket_name)
    find_or_create_bucket!(bucket_name)
    sync_files(bucket_name, File.expand_path("../../../cra/build", __FILE__))
  end

  def sync_files(bucket_name, root_dir)
    manifest = scan(root_dir)

    response = client.list_objects_v2(bucket: bucket_name)
    response.contents.each do |item|
      client.delete_object(bucket: bucket_name, key: item.key) unless manifest.key?(item.key)
    end

    manifest.each do |key, path|
      client.put_object(bucket: bucket_name, key: key, body: File.read(path))
    end
  end

  def scan(dir, base=dir)
    results = {}
    Dir["#{dir}/*"].each do |path|
      if File.directory?(path)
        results.merge!(scan(path, base))
      else
        results[path[(base.length + 1)..]] = path
      end
    end

    results
  end

  private

  attr_reader :client

  def find_or_create_bucket!(bucket_name)
    client.head_bucket(bucket: bucket_name)
  rescue Aws::S3::Errors::ServiceError
    client.create_bucket(
      bucket: bucket_name,
    )
    client.put_bucket_website(
      bucket: bucket_name,
      website_configuration: {
        error_document: {
          key: "index.html", 
        },
        index_document: {
          suffix: "index.html", 
        } 
      }
    )
    client.put_public_access_block(
      bucket: bucket_name,
      public_access_block_configuration: {
        block_public_acls: false,
        block_public_policy: false,
        ignore_public_acls: false,
        restrict_public_buckets: false
      }
    )
    client.put_bucket_policy(
      bucket: bucket_name,
      policy: {
        "Version" => "2012-10-17",
        "Statement" => [
          {
            "Sid" => "AddPerm",
            "Effect" => "Allow",
            "Principal" => "*",
            "Action" => "s3:GetObject",
            "Resource": "arn:aws:s3:::#{bucket_name}/*"
          }
        ]
      }.to_json
    )
  end
end