require "sbs/version"
require "thor"
require "fileutils"
require "find"
require "active_support/core_ext/string"
require "colorize"

module Sbs
  class Error < StandardError; end

  class Cli < Thor
    desc "new CHAIN_NAME", "Create a new blockchain from substrate node template by branch."
    option :author, :aliases => :a, :default => "wuminzhe"
    option :branch, :aliases => :b, :default => "master"
    def new(chain_name)
      dest_dir = "."

      # generate your chain
      if generate_from_node_template(chain_name, options[:branch], options[:author], dest_dir)
        # build
        Dir.chdir("#{dest_dir}/#{chain_name}") do
          puts "*** Initializing WebAssembly build environment..."
          `./scripts/init.sh`
          
          puts "*** Building '#{chain_name}' ..."
          if File.exist?("./scripts/build.sh")
            `./scripts/build.sh`
          end
          `cargo build`
        end

        puts ""
        puts "Your blockchain '#{chain_name}' has been generated."
        puts ""
      end
    end

    desc "check", "Check the rust environment and substrate version used by your project. Do it in your project directory."
    def check
      if `which rustc`.strip != ""
        puts "Your rust environment:"
        puts "  default: #{`rustc --version`}"
        puts ""

        puts "  stable: #{`rustc +stable --version`}"
        puts "    targets: "
        `rustup target list --installed --toolchain stable`.each_line do |line|
          puts "      #{line}"
        end
        puts ""

        puts "  nightly: #{`rustc +nightly --version`}"
        puts "    targets: "
        `rustup target list --installed --toolchain nightly`.each_line do |line|
          puts "      #{line}"
        end
        puts ""

        puts "  all toolchains: "
        `rustup toolchain list`.each_line do |line|
          puts "    #{line}"
        end
        puts ""
      end

      puts "The substrate version your project depends:"
      get_commits.each do |commit|
        puts "#{commit}"
      end
      puts ""
    end

    desc "diff", "Show the difference between your substrate version and branch head. Do it in your project directory."
    option :list, :aliases => :l, :type => :boolean
    option :full, :aliases => :f, :type => :boolean
    option :branch, :aliases => :b, :default => "master"
    def diff
      commits = get_commits
      if commits.length > 1
        puts "Your project seems to depend on more than one substrate commit"
        return
      end
      commit = commits[0]

      home = File.join(Dir.home, ".sbs")
      substrate_dir = File.join(home, "substrate")
      tmp = File.join(home, "tmp", "/")
      tmp_dir_1 = File.join(tmp, "your")
      tmp_dir_2 = File.join(tmp, options[:branch])
      FileUtils.mkdir_p(tmp_dir_1)
      FileUtils.mkdir_p(tmp_dir_2)

      # Compare the differences between the node-template you depend on and the latest node-template of the branch
      node_template_1 = copy_node_template(commit, tmp_dir_1)
      node_template_2 = copy_node_template(options[:branch], tmp_dir_2)

      diff_cmd = "diff -rq #{tmp_dir_1}/#{node_template_1} #{tmp_dir_2}/#{node_template_2}"

      if (not options[:list]) && (not options[:full]) && (`fzf --version` =~ /^\d+\.\d+\.\d /)
        diff = `#{diff_cmd} | fzf`
        show_file_diff(tmp, diff)
      else
        diffs = `#{diff_cmd}`
        diffs.each_line do |diff|
          if options[:list]
            puts(diff.gsub(tmp, "").colorize(:green).underline) unless diff.include?("Cargo.lock")
          else
            show_file_diff(tmp, diff) unless diff.include?("Cargo.lock")
          end
        end
      end 
    end

    private
    def copy_node_template(branch_or_commit, dest_dir)
      # clone or update substrate
      home = File.join(Dir.home, ".sbs")
      Dir.mkdir(home) if not Dir.exist?(home)
      substrate_dir = File.join(home, "substrate")

      if not Dir.exist?(substrate_dir)
        `git clone -q https://github.com/paritytech/substrate #{substrate_dir}`
      end

      Dir.chdir substrate_dir do
        `git checkout -q master`
        `git pull -q`
      end

      # check exist
      Dir.chdir substrate_dir do
        if `git cat-file -t #{branch_or_commit}`.strip != "commit"
          raise "Not a valid branch or commit: #{branch_or_commit}"
        end
      end

      # get commit if it is a branch
      commit = `git ls-remote https://github.com/paritytech/substrate refs/heads/#{branch_or_commit} | cut -f 1`.strip
      commit = branch_or_commit if commit == "" 

      # checkout commit and then copy to dest dir
      node_template_name = "node-template-#{commit[0 .. 9]}"
      if not Dir.exist?("#{dest_dir}/#{node_template_name}")
        Dir.chdir substrate_dir do
          `git checkout -q #{commit}`
          `cp -R ./node-template #{dest_dir}/#{node_template_name}`
        end
      end

      return node_template_name
    end

    def show_file_diff(tmp, diff)
      if diff.start_with?("Files")
        scans = diff.scan(/Files (.+) and (.+) differ/)
        file1 = scans[0][0]
        file2 = scans[0][1]

        puts diff.gsub(tmp, "").colorize(:green).underline
        puts `diff -u #{file1} #{file2}`.gsub(tmp, "")
        puts "\n"
      else
        puts diff.gsub(tmp, "").colorize(:green).underline
        puts "\n"
      end
    end

    def generate_from_node_template(chain_name, branch_or_commit, author, dest_dir)
      home = File.join(Dir.home, ".sbs")
      Dir.mkdir(home) if not Dir.exist?(home)
      substrate_dir = File.join(home, "substrate")

      puts "*** Preparing substrate..."
      if not Dir.exist?(substrate_dir)
        `git clone https://github.com/paritytech/substrate #{substrate_dir}`
      end

      # checkout branch or commit
      is_branch = false
      Dir.chdir substrate_dir do
        if `git cat-file -t #{branch_or_commit}`.strip != "commit"
          puts "Not a valid branch or commit"
          return
        else
          `git checkout #{branch_or_commit}`
          if `git show-ref refs/heads/#{branch_or_commit}`.strip != "" # this is a branch
            is_branch = true
            `git pull`
          end
        end
      end

      puts "*** Copying node-template for '#{chain_name}' ..."
      if not Dir.exist?("#{dest_dir}/#{chain_name}")
        `cp -R #{substrate_dir}/node-template #{dest_dir}/#{chain_name}`
      end

      Dir.chdir("#{dest_dir}/#{chain_name}") do
        puts "*** Customizing '#{chain_name}' ..."
        Find.find(".") do |path|
          if not File.directory? path
            content = `sed "s/Substrate Node Template/#{chain_name.titleize} Node/g" "#{path}"`
            File.open(path, "w") do |f| f.write(content) end

            content = `sed "s/Substrate Node/#{chain_name.titleize} Node/g" "#{path}"`
            File.open(path, "w") do |f| f.write(content) end

            content = `sed "s/Substrate node/#{chain_name.titleize} node/g" "#{path}"`
            File.open(path, "w") do |f| f.write(content) end

            content = `sed "s/node_template/#{chain_name.titleize.gsub(" ", "").underscore}/g" "#{path}"`
            File.open(path, "w") do |f| f.write(content) end

            content = `sed "s/node-template/#{chain_name.titleize.downcase.gsub(" ", "-")}/g" "#{path}"`
            File.open(path, "w") do |f| f.write(content) end

            if path.end_with?("toml")
              if not author.nil?
                content = `sed "s/Anonymous/#{author}/g" "#{path}"`
                File.open(path, "w") do |f| f.write(content) end
              end

              if is_branch
                sed = "sed \"s/path = \\\"\\\.\\\.\\\/.*\\\"/git = 'https:\\\/\\\/github.com\\\/paritytech\\\/substrate.git', branch='#{branch_or_commit}'/g\" #{path}"
              else
                sed = "sed \"s/path = \\\"\\\.\\\.\\\/.*\\\"/git = 'https:\\\/\\\/github.com\\\/paritytech\\\/substrate.git', rev='#{branch_or_commit}'/g\" #{path}"
              end
              content = `#{sed}`
              File.open(path, "w") do |f| f.write(content) end
            end
          end
        end
        
        puts "*** Initializing '#{chain_name}' repository..."
        `git init 2>/dev/null >/dev/null`
        `touch .gitignore`
        File.open(".gitignore", "w") do |f|
          gitignore = %q(# Generated by Cargo
# will have compiled files and executables
**/target/
# These are backup files generated by rustfmt
**/*.rs.bk)
          f.write(gitignore)
        end
      end

      true
    end

    def get_commits
      if not File.exist?("./Cargo.lock")
        puts "There is no Cargo.lock in current directory!"
        return
      end

      content = File.open("./Cargo.lock").read
      result = content.scan(/substrate\.git(.*#.+)"$/).uniq

      commits = []
      result.each do |item|
        splits = item[0].split("#")
        commits << splits[1].strip
      end
      
      commits.uniq
    end

  end
end

Sbs::Cli.start(ARGV)
