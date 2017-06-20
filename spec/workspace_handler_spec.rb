require './lib/workspace_handler'

describe WorkspaceHandler do
  let(:file_name_template) { 'project_2012-07-27_*_performancedata.txt' }
  let(:base_folder) { "#{Dir.pwd}/spec/data" }
  subject { WorkspaceHandler.new(file_name_template, base_folder).latest_file }

  context "#latest_file" do
    it "Should give the last by date file" do
      expect(File.basename(subject.file_path)).to eq('project_2012-07-27_2012-12-10_performancedata.txt')
    end
  end

  context "#sort" do
    it "File should be sorted by Click column value" do
      subject.sort
      expect(File.read(subject.file_path)).to eq(File.read("#{base_folder}/sorted.txt"))
    end
  end
end


