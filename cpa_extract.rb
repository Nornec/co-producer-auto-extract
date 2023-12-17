#This script renames all sample files provided by Output's Co-producer and standardizes the naming scheme
# and places all appropriately named .wavs into separate tempo directories
require 'optparse'
require 'date'
require 'zip'

options = {}
OptionParser.new do |opt|
  opt.on('--directory DIR') { |o| options[:directory] = o }
  opt.on('-d DIR') {|o| options[:directory] = o }
end.parse!

if options[:directory] != nil then 
  working_dir = File.dirname(options[:directory])
else exit()
end

zip_files = []
wav_files = []

#Get all *sample-pack.zip files in the given directory. Quit if no .zips found
zip_files = Dir[options[:directory]+"/*sample-pack.zip"]
if zip_files.length() == 0 then 
  puts "No *sample-pack.zip files found to process. Exiting..."
  quit()
else
  puts "Found some Co-producer sample packs! Getting to work.."
end

#Recursively extract all .wavs from the "sample pack" folder into the input directory
zip_files.each do |z|
  puts "Processing zip: " + z
  Zip::File.open(z) do |zfile|
		zfile.each do |entry|
			if entry.name.match(/^sample pack/)
      then 
        wav_name = entry.name[entry.name.rindex(/\//) + 1..-1]
        zfile.extract(entry, options[:directory] + "/" + wav_name)
      end
		end
  end
  File.delete(z)
end

#Get all .wav filenames from the input directory
wav_files = Dir[options[:directory]+"/*.wav"]
if wav_files.length() == 0 then 
  puts "No .wav files found to process. Exiting..."
  quit() 
end

last_track = ""
track_counter = 1
new_track_names = []

wav_files.sort.each do |x|
  puts "Processing file " + x
  orig_name = x
  last_brack = x.rindex(/\//) + 1
  x = x[last_brack..-1]
  words = x.split("_")

  #Find bpm in file name
  bpm_index = words.find_index("BPM") - 1
  bpm = words[bpm_index]

  #Get track name from file name  
  track_name_parts = words[0..bpm_index-1]
	
  #Remove erroneous number from end of track name, we will supply our own
  if track_name_parts[-1].match(/^\d+/) then track_name_parts.pop end
  
  track = ""
  track_name_parts.each do |n|
    track = track + " " + n
  end
  
  track = track.strip
  if track == last_track then track_counter += 1
  else track_counter = 1
  end
  last_track = track

  track = track_counter.to_s + " ][ " + track
  bpm_dir_name = options[:directory] + "/" + bpm + " bpm"
  Dir.mkdir(bpm_dir_name) unless Dir.exists?(bpm_dir_name)
  new_name = bpm_dir_name + "/" + track + "." + Time.now.strftime("%Y%m%d.%H.%M") + ".wav"
  
  File.rename(orig_name, new_name)
end
