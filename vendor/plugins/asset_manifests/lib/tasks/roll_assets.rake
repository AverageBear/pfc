require File.expand_path('../../asset_manifest/javascript_asset_manifest', __FILE__)
require File.expand_path('../../asset_manifest/css_asset_manifest', __FILE__)

namespace :assets do
  task :roll => %w[css:roll js:roll]
  task :unroll => %w[css:unroll js:unroll]
  task :prepare => %w[css:prepare js:prepare]

  namespace :css do
    task :prepare => %w[css:roll]

    task :roll do
      STDERR.puts "  ** Rolling CSS files..."
      CSSAssetManifest.roll_files(:all)
    end

    task :unroll do
      STDERR.puts "  ** Unrolling CSS files..."
      begin
        CSSAssetManifest.unroll_files(:all)
      rescue Exception => e
      end
    end
  end

  namespace :js do
    task :prepare => %w[js:generate js:roll]

    task :generate => %w[public/javascripts/wesabe/data/currency-data.js]

    file 'public/javascripts/wesabe/data/currency-data.js' => 'app/models/currency.rb' do |t|
      # This is not in the dep list because non-file task dependencies force
      # the task to run, even when the file is not out of date.
      Rake::Task['environment'].invoke

      File.open(t.name, 'w') do |f|
        f.puts %{// DO NOT EDIT THIS FILE}
        f.puts %{// This file is automatically generated by #{File.basename(__FILE__)} based on currency.rb.}
        f.puts
        f.puts %{wesabe.data.currencies.set(#{Currency.data.to_json});}
      end
    end

    file 'public/javascripts/wesabe/data/state-data.js' => 'lib/constants.rb' do |t|
      # This is not in the dep list because non-file task dependencies force
      # the task to run, even when the file is not out of date.
      Rake::Task['environment'].invoke

      File.open(t.name, 'w') do |f|
        f.puts %{// DO NOT EDIT THIS FILE}
        f.puts %{// This file is automatically generated by #{File.basename(__FILE__)} based on lib/constants.rb.}
        f.puts
        f.puts %{wesabe.data.states.set(#{Constants::STATES.to_json});}
      end
    end

    task :roll do
      STDERR.puts "  ** Rolling Javascript files..."
      JavaScriptAssetManifest.roll_files(:all)
      JavaScriptAssetManifest.manifests.each do |manifest|
        STDERR.puts "  ** Minifying #{manifest.name}.js file..."
        begin
          file = manifest.rolled_filepath
          minified_file = "#{manifest.rolled_filepath}.minified"
          system "script/js-minify < #{file} > #{minified_file}"
          saved_bytes = File.size(file) - File.size(minified_file)
          system "mv #{minified_file} #{file}"
          STDERR.puts "  ** Saved #{saved_bytes / 1024}KB! Yay everyone!"
        rescue => e
          STDERR.puts "  ** Error minifying Javascript file, using un-minified version"
        end
      end
    end

    task :unroll do
      STDERR.puts "  ** Unrolling Javascript files..."
      begin
        JavaScriptAssetManifest.unroll_files(:all)
      rescue Exception => e
      end
    end
  end
end
