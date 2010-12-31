#!/usr/bin/env ruby

require "rubygems"
require "awesome_print"

require "json"
require "net/http"
require "uri"
require "fileutils"

def main(args)
  baseurl = "http://registry.npmjs.org"
  package = args.shift
  version = (args.shift or "latest")

  if package == nil
    $stderr.puts "What npm package?"
    return 1
  end

  url = URI.parse("#{baseurl}/#{package}/#{version}")

  response = Net::HTTP.get_response(url)
  if response.code.to_i != 200
    $stderr.puts "An error occurred: #{response}"
    return 1
  end

  data = JSON.parse(response.body)
  return install(data, ENV["DESTDIR"])
end # def main

def install(data, destdir)
  # directories are directories to copy
  # directories.lib are directories to copy
  # author is the author
  # licenses is an array of licenses. Use data["licenses"][0]["type"]
  # bin is a hash of tool -> script
  # homepage
  # engines is a hash of node engines supported?
  # dependencies is a hash of package => version deps
  # devDependencies is hash of package => version deps
  # dist/tarball is the url for the data
  
  ap data
  prefix = "#{destdir}/usr/lib/node/#{data["name"]}@#{data["version"]}"

  tarball_url = URI.parse(data["dist"]["tarball"])
  tarball = File.new(File.basename(tarball_url.path), "w")
  puts "Downloading #{tarball_url}"
  response = Net::HTTP.get_response(tarball_url)
  if response.code.to_i != 200
    $stderr.puts "An error occurred while downloading the package: #{response}"
    return 1
  end

  tarball.write(response.body)
  tarball.close()

  FileUtils.mkdir_p(prefix)

  # Selectively unpack directories from the tarball into destdir.
  system("tar -C #{prefix} -zxf #{tarball.path}")
  packagedirs = (data["directories"]["lib"] or [])
  packagedirs.each do |path|
    source = File.join(prefix, "package", path)
    dest = File.join(prefix, path)
    FileUtils.mkdir_p(dest)
    system("mv #{source} #{dest}")
  end
  system("rm -r #{File.join(prefix, "package")}")

  File.delete(tarball.path)

end # def install

exit(main(ARGV))
