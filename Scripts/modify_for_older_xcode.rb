#!/usr/bin/env ruby

require 'pathname'
require 'xcodeproj'

ROOT = Pathname.new(File.expand_path('../../', __FILE__))

project = Xcodeproj::Project.open(ROOT + 'mParticle-Apple-SDK.xcodeproj')
target = project.targets.find { |t| t.name == 'mParticle-iOS-SDK' }

frameworks_build_phase = target.frameworks_build_phase

build_files = frameworks_build_phase.files.select do |build_file|
  build_file.display_name =~ /^(UserNotifications\.framework)$/i
end

build_files.each do |build_file|
  frameworks_build_phase.remove_build_file(build_file)
end

groups = project.main_group.recursive_children_groups
groups << project.main_group

files = groups.flat_map do |group|
  group.files.select do |obj|
    obj.name =~ /^UserNotifications\.framework$/i
  end
end

unless files.empty?
  files.each do |file_reference|
    file_reference.remove_from_project
  end
end

project.save
