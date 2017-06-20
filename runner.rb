require_relative 'modifier'
require_relative 'lib/workspace_handler'

workspace1 = WorkspaceHandler.new('project_2012-07-27_*_performancedata.txt')
workspace2 = WorkspaceHandler.new('project_2012-08-27_*_performancedata.txt')

modifier = Modifier.new(saleamount_factor: 1, cancellation_factor: 0.4)
# enum1 = workspace.latest_file.sort.lazy_read
# enum2 = enum1.dup

modified_data = modifier.proceed(workspace1.latest_file.sort.lazy_read, workspace2.latest_file.sort.lazy_read)
workspace1.output_with_pagination modified_data
puts "DONE modifying"
