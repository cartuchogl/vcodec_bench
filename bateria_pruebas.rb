# This file is part of vcodec_bench.
# 
# EseaTetris is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# vcodec_bench is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with EseaTetris. If not, see <http://www.gnu.org/licenses/>.

class Prueba
  attr_accessor :input
  attr_accessor :codecs
  attr_accessor :bitrates
  attr_accessor :results
  attr_writer :input_name
  attr_accessor :ffextra  
  
  def get_binding
    binding
  end
  
  def run
    @mapext = {
      :theora => 'ogv',
      :h264   => 'mp4',
      :xvid   => 'avi',
      :flv    => 'flv'
    }
    @results = {}
    transcode
    take_screenshots
    quality_frames_comparation
    @input_name = input_name
    do_results
  end
  
  def input_name
    if @input_name
      @input_name
    else
      input
    end
  end
  
  def ext(codec)
    @mapext[codec]
  end
  
  def ffmpeg_codec(codec)
    {
      :theora => ['libtheora','libtheora'],
      :h264   => ['libx264 -vpre slow_firstpass','libx264 -vpre slow'],
      :xvid   => ['libxvid','libxvid'],
      :flv    => ['flv','flv']
    }[codec]
  end
  # for i in {1200..2200}; do mv `printf "big_buck_bunny_%05d.png big_buck_bunny_%05d.png" "$i" "$((i-1200))"`; done
  def transcode
    bitrates.each do |b|
      codecs.each do |c|
        results[c] = {} unless results[c]
        start_time = Time.now
        cmd = "ffmpeg -y -i #{input} -an -pass 1 -vcodec #{ffmpeg_codec(c).first} -b #{b} -bt #{b} -threads 0 #{ffextra} #{input_name}.#{b}.#{ext(c)}"
        puts cmd
        `#{cmd}`
        cmd = "ffmpeg -y -i #{input} -an -pass 2 -vcodec #{ffmpeg_codec(c).first} -b #{b} -bt #{b} -threads 0 #{ffextra} #{input_name}.#{b}.#{ext(c)}"
        `#{cmd}`
        end_time = Time.now
        puts "#{c} at #{b} in"
        puts end_time - start_time
        results[c][b] = {:trans_time => end_time - start_time }
        results[c][b][:filesize] = File.size("#{input_name}.#{b}.#{ext(c)}")
      end
    end
  end
  
  def take_screenshots
    cmd = "ffmpeg -i #{input} -an -vframes 1 #{input_name}.orig.png"
    `#{cmd}`
    bitrates.each do |b|
      codecs.each do |c|
        cmd = "ffmpeg -i #{input_name}.#{b}.#{ext(c)} -an -vframes 1 #{input_name}.#{b}.#{ext(c)}.png"
        `#{cmd}`
      end
    end
  end
  
  def quality_frames_comparation
    require 'RMagick'
    codecs.each do |c|
      bitrates.each do |b|
        imgs = Magick::ImageList.new("#{input_name}.orig.png", "#{input_name}.#{b}.#{ext(c)}.png")
        results[c][b][:diff] = imgs[0].difference(imgs[1])
        puts "#{c} at #{b}"
        puts results[c][b][:diff]
      end
    end
  end
  
  def do_results
    require "erb"
    puts "...making html statistics..."
    template = File.read('statistics.html.erb').gsub(/^  /, '')
    rhtml = ERB.new(template)
    File.open("statistics.html", 'w') {|f| f.write(rhtml.result(self.get_binding)) }
    
    template = File.read('visual.html.erb').gsub(/^  /, '')
    rhtml = ERB.new(template)
    File.open("visual.html", 'w') {|f| f.write(rhtml.result(self.get_binding)) }
    
    puts "..................END.................."
    puts results.inspect
  end
  
end
# shinedown , second chance

prueba = Prueba.new
prueba.input = 'input.vob'
prueba.codecs = [:h264,:theora]
prueba.bitrates = ['1024k','768k','512k','384k','256k']
prueba.run

