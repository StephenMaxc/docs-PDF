# frozen_string_literal: true

Prawn::Table::Cell.prepend (Module.new do
  attr_writer :source_location

  def border_color= color
    color = [color, color] if Asciidoctor::PDF::ThemeLoader::CMYKColorValue === color
    super
  end

  # Draws borders around the cell. Borders are centered on the bounds of
  # the cell outside of any padding, so the caller is responsible for
  # setting appropriate padding to ensure the border does not overlap with
  # cell content.
  #
  # Adds support for transparent border color.
  #
  def draw_borders pt
    x, y = pt

    @pdf.mask :line_width, :stroke_color do
      @borders.each do |border|
        idx = { top: 0, right: 1, bottom: 2, left: 3 }[border]
        border_color = @border_colors[idx]
        border_width = @border_widths[idx]
        border_line  = @border_lines[idx]

        next unless border_width > 0

        # Left and right borders are drawn one-half border beyond the center
        # of the corner, so that the corners end up square.
        case border
        when :top
          from, to = [[x, y], [x + width, y]]
        when :bottom
          from, to = [[x, y - height], [x + width, y - height]]
        when :left
          from, to = [[x, y + (border_top_width / 2.0)], [x, y - height - (border_bottom_width / 2.0)]]
        else # :right
          from, to = [[x + width, y + (border_top_width / 2.0)], [x + width, y - height - (border_bottom_width / 2.0)]]
        end

        case border_line
        when :dashed
          @pdf.dash border_width * 4
        when :dotted
          @pdf.dash border_width
        when :solid
          # normal line style
        else
          raise ArgumentError, 'border_line must be :solid, :dotted or :dashed'
        end

        @pdf.line_width = border_width
        if border_color == 'transparent'
          @pdf.stroke_color = '000000'
          @pdf.transparent 0 do
            @pdf.stroke_line from, to
          end
        else
          @pdf.stroke_color = border_color
          @pdf.stroke_line from, to
        end
        @pdf.undash
      end
    end
  end
end)
