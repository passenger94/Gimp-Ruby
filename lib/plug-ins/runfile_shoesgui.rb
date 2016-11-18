
require File.expand_path("shoesfu.rb", File.dirname(__FILE__))
include ShoesFu

Shoes.app :width => 600, :height => 400, :title => "Run Plugin File" do
    
    @drawables = gimp_says
    
    stack do
        flow do
            @el = edit_line "", width: 500
            
            button "Browse" do
                @filename = ask_open_file
                @el.text = @filename
                matches = File.read(@filename).scan(/name.+(ruby-fu-.*)["'].*/).flatten
                if matches.empty?
                    error "Sorry ...\ndidn't find a ruby-fu function in\n#{@filename}\n"
                    Shoes.show_log
                end
                
                @procname = matches[0]
                if matches.size == 1
                    @fmulti.hide; @f1.show
                    @func_name.text = @procname
                else
                    @fmulti.show; @f1.hide
                    @func_names.items = matches
                    @func_names.choose @procname
                end
            end
        end

        @f1 = flow hidden: true do
            para "found one ruby-fu procedure : "
            @func_name = para ""
        end

        @fmulti = flow hidden: true do
            para "found multiple ruby-fu procedures,\nPlease select one : "
            @func_names = list_box(width: 350) { |lb| @procname = lb.text }
        end

        flow do
            para "Select the active drawable : "
            @drawables_lb = list_box width: 350, items: @drawables, choose: @drawables[0]
        end
        
        flow do
            button "Run" do
                tell_gimp [@filename, @procname, @drawables_lb.text].to_json
                exit
            end

            button "Cancel" do
                tell_gimp ["cancelled"]
                exit
            end
        end
    end

    
end