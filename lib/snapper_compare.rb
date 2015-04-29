require 'chunky_png'
require_relative 'utils'

include ChunkyPNG::Color

# class for comparing png files.Comparison is limited two between 2 files at a time.
class ImageComparison
  attr_accessor :images, :log, :diff_img, :max_width, :max_height

  def initialize(route, image1, image2, log_dir="logs")
    @log_dir = log_dir
    @log = Utils::Log.new(true, true)

    route  = route.nil? ? "unknown" : route
    @diff_img = "#{@log_dir}/#{route}_diff.png"

    if !image1.nil? && !image2.nil?
      @images = [
        ChunkyPNG::Image.from_file(image1),
        ChunkyPNG::Image.from_file(image2)
      ]

      @max_width = 0
      @max_height = 0
    else
      @log.error("One of the provided images is null: image1=>[#{image1}] image2=>[#{image2}]")
    end
  end

  # function to check if the two images have the same dimensions
  def image_dimensions_match?
    @images_match = false
    diff = []
    if @images.first.pixels.length == @images.last.pixels.length
      if @images.first.width == @images.last.width
        @log.info("Image dimensions match")
        images_match = true
      else
        @log.warn("Image width DOESN'T match")
      end
    else
      @log.warn("Image size DOESN'T match")
    end

    @max_width = @images.first.width > @images.last.width ? @images.first.width : @images.last.width
    @max_height = @images.first.height > @images.last.height ? @images.first.height : @images.last.height

    @log.info("Image 1: #{@images.first.width} X #{@images.first.height} Pixels: #{@images.first.pixels.length}")
    @log.info("Image 2: #{@images.last.width} X #{@images.last.height} Pixels: #{@images.last.pixels.length}")
    return images_match
  end

  # this comparison just determines if an image differs and saves a diffed area
  def quick_compare_images
    @log.info('Quick comparison started...')
    diff = []
    @images.first.height.times do |y|
      @images.first.row(y).each_with_index do |pixel, x|
        diff << [x,y] unless pixel == @images.last[x,y]
      end
    end

    percentage_change = (diff.length.to_f / @images.first.pixels.length.to_f) * 100

    @log.info('##########################')
    @log.info("Pixels (Total):     #{@images.first.pixels.length}")
    @log.info("Pixels changed      #{diff.length}")
    @log.info("Pixels changed (%): #{percentage_change}%")
    @log.info('##########################')

    x, y = diff.map{ |xy| xy[0] }, diff.map{ |xy| xy[1] }

    @images.last.rect(x.min, y.min, x.max, y.max, ChunkyPNG::Color.rgb(0,255,0))
    @images.last.save("#{@log_dir}/#{@diff_img}")

    if diff.length > 0
      true #images differ
    else
      false
    end
  end

  # this comparison determines where in the images they differ and writes that difference
  # to a file
  def detailed_compare_images
    diff = []
    @log.info('Detailed Comparison started...')
    output_temp = ChunkyPNG::Image.new(@max_width, @max_height, WHITE)

    @images.first.height.times do |y|
      @images.first.row(y).each_with_index do |pixel, x|
        unless pixel == @images.last[x,y]
          score = Math.sqrt(
            (r(@images.last[x,y]) - r(pixel)) ** 2 +
            (g(@images.last[x,y]) - g(pixel)) ** 2 +
            (b(@images.last[x,y]) - b(pixel)) ** 2
          ) / Math.sqrt(MAX ** 2 * 3)

          begin
            output_temp[x,y] = grayscale(MAX - (score * MAX).round)
            diff << score
          rescue
            @log.info("Images not the same. Different sizes")
          end
        end
      end
    end

    pixel_diff_count  = diff.inject {|sum, value| sum + value}
    percentage_change = (pixel_diff_count.to_f / @images.first.pixels.length.to_f) * 100

    puts('##########################')
    @log.info("Pixels (Total):     #{@images.first.pixels.length}")
    @log.info("Pixels changed:     #{pixel_diff_count}")
    @log.info("Image changed (%):  #{percentage_change}%")
    puts('##########################')

    @log.info("Writing diff file: #{@diff_img}")
    output_temp.save("#{@diff_img}")

    if diff.length > 0
      @log.warn("Images differ")
      return 0 #images differ
    else
      @log.info("Images are identical")
      return 1
    end
  end
end
