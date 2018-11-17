require 'fileutils'

desc "Install dotfiles."
task :install do
  Dir["#{File.dirname __FILE__}/**/*.copy"].each do |copy_file|
    dest_file = %Q{#{ENV['HOME']}/.#{File.basename( copy_file ).chomp(".copy")}}
    FileUtils.cp copy_file, dest_file
  end

  Dir["#{File.dirname __FILE__}/**/*.symlink"].each do |symlink_file|
    dest_file = %Q{#{ENV['HOME']}/.#{File.basename( symlink_file ).chomp(".symlink")}}

    if ENV['FORCE'] && File.exists?(dest_file)
      FileUtils.rm dest_file
    end

    if !File.exists?(dest_file)
      FileUtils.ln_s symlink_file, dest_file
    end
  end
end
