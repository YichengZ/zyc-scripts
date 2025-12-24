#!/usr/bin/env ruby
# ReaPack Index Generator for zyc-scripts
# 自动生成包含所有文件的 index.xml

require 'fileutils'
require 'time'

REPO_URL = "https://github.com/YichengZ/zyc-scripts"
BRANCH = "main"
BASE_PATH = "Release/REAPER/Scripts/ReaPet"

def get_file_url(relative_path)
  "#{REPO_URL}/raw/#{BRANCH}/#{relative_path}"
end

def find_all_files(base_dir)
  files = []
  Dir.glob("#{base_dir}/**/*").each do |file|
    next if File.directory?(file)
    next if file.include?('.DS_Store')
    next if file.include?('.git')
    
    # 只包含必要的文件类型
    if file.match(/\.(lua|png|jpg|jpeg|json)$/i)
      files << file
    end
  end
  files.sort
end

def get_relative_path(full_path)
  # 从 Release/ 开始计算相对路径
  if full_path.include?("Release/")
    "Release/" + full_path.split("Release/")[1]
  elsif full_path.start_with?("Release/")
    full_path
  else
    "Release/" + full_path
  end
end

def is_main_file(file_path)
  file_path.end_with?("zyc_ReaPet.lua")
end

# 生成 XML
puts "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
puts "<index version=\"1\" name=\"Zyc Scripts\" commit=\"#{`git rev-parse HEAD`.strip[0..6]}\">"
puts "  <category name=\"Effects\">"
puts "    <reapack name=\"zyc_EnvFollower.jsfx\" type=\"effect\" desc=\"Professional envelope follower with Peak/RMS detection\">"
puts "      <version name=\"1.0.0\" author=\"EthanZhu\" time=\"2025-01-21T00:00:00Z\">"
puts "        <changelog><![CDATA[Initial release - Professional envelope follower with Peak/RMS detection]]></changelog>"
puts "        <source main=\"main\">#{get_file_url("Release/REAPER/Effects/zyc_EnvFollower.jsfx")}</source>"
puts "      </version>"
puts "    </reapack>"
puts "    <reapack name=\"zyc_LFO.jsfx\" type=\"effect\" desc=\"Advanced LFO modulator with 7 waveform types\">"
puts "      <version name=\"1.0.0\" author=\"EthanZhu\" time=\"2025-01-21T00:00:00Z\">"
puts "        <changelog><![CDATA[Initial release - Lite version with core LFO features]]></changelog>"
puts "        <source main=\"main\">#{get_file_url("Release/REAPER/Effects/zyc_LFO.jsfx")}</source>"
puts "      </version>"
puts "    </reapack>"
puts "  </category>"
puts "  <category name=\"Scripts\">"
puts "    <reapack name=\"zyc_ReaPet\" type=\"script\" desc=\"REAPER companion app with stats tracking, pomodoro timer, treasure box system, and multiple character skins\">"
puts "      <version name=\"1.0.0\" author=\"Yicheng Zhu (Ethan)\" time=\"#{Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")}\">"
puts "        <changelog><![CDATA["
puts "v1.0.0 (2025-12-24)"
puts "- Initial release"
puts "- Operation statistics (global and project level)"
puts "- Pomodoro timer functionality"
puts "- Treasure box system (plugin recommendations)"
puts "- Coin system and shop"
puts "- 8 character skins (cat, dog, bear, rabbit, koala, lion, onion, chick)"
puts "- Multi-project support with automatic data switching"
puts "        ]]></changelog>"

# 添加所有文件
files = find_all_files(BASE_PATH)

# 先添加主文件
main_file = files.find { |f| is_main_file(f) }
if main_file
  relative_path = get_relative_path(main_file)
  url = get_file_url(relative_path)
  puts "        <source main=\"main\">#{url}</source>"
end

# 然后添加其他文件
files.each do |file|
  next if is_main_file(file)  # 主文件已添加
  
  relative_path = get_relative_path(file)
  url = get_file_url(relative_path)
  puts "        <source>#{url}</source>"
end

# 如果主文件不存在，添加默认路径
unless main_file
  main_url = get_file_url("Release/REAPER/Scripts/ReaPet/zyc_ReaPet.lua")
  puts "        <source main=\"main\">#{main_url}</source>"
end

puts "      </version>"
puts "    </reapack>"
puts "  </category>"
puts "  <metadata>"
puts "    <description><![CDATA[Professional REAPER scripts by EthanZhu"
puts ""
puts "Effects:"
puts "- zyc_EnvFollower: Professional envelope follower with Peak/RMS detection"
puts "- zyc_LFO: Advanced LFO modulator with 7 waveform types"
puts ""
puts "Scripts:"
puts "- zyc_ReaPet: REAPER companion app with stats tracking, pomodoro timer, treasure box system, and multiple character skins]]></description>"
puts "    <link rel=\"website\">#{REPO_URL}</link>"
puts "  </metadata>"
puts "</index>"

