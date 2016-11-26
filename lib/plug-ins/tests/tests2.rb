#!ruby

require "rubyfu"
include RubyFu

assert = ->(obj, met) {
    func = "ruby-fu-test-drawable-subclass-#{obj.downcase}"
    register(
        :name       => func,
        :blurb      => "...",
        :help       => "",
        :author     => nil,
        :copyright  => nil,
        :date       => nil,
        :menulabel  => nil,
        :imagetypes => "*",
        :params     => [],
        :results    => []
    ) do |run_mode, image, drawable|
        include PDB::Access
        
        msg = "Should respond to a #{obj} method \n"
        begin
            drawable.send(met)
            msg << "Success ! we are working with a #{drawable.class}"
        rescue => e
            msg << "#{e.to_s}\n#{e.backtrace.join("\n")}"
        ensure
            message msg
        end
    end
    
    menu_register(func, "<NoMenu>")
}

assert.call("Layer", :floating_sel?)
assert.call("Channel", :get_show_masked)


register(
    :name       => "ruby-fu-test-drawable-subclass-mock",
    :blurb      => "...",
    :help       => "",
    :author     => nil,
    :copyright  => nil,
    :date       => nil,
    :menulabel  => "Drawable SubClass ...",
    :imagetypes => nil,
    :params     => [],
    :results    => []
) do |run_mode|
    include PDB::Access
    
    img = Image.new 256, 256, RGB
    ly1 = img.addLayer(img.width, img.height, RGBA_IMAGE, "test layer", 100, NORMAL_MODE)
    ch1 = Channel.new_from_component(img, RED_CHANNEL, "test channel")
    img.insert_channel(ch1, 0, -1)
    Display.new(img)
    
    ruby_fu_test_drawable_subclass_layer(img, ly1)
    ruby_fu_test_drawable_subclass_channel(img, ch1)
    
end

menu_register("ruby-fu-test-drawable-subclass-mock", "<Image>/Filters/Ruby-Fu_Toolbox/Test")


register(
    :name       => "ruby-fu-test-gimp_pdb_proc_exists",
    :blurb      => "...",
    :help       => "",
    :author     => nil,
    :copyright  => nil,
    :date       => nil,
    :menulabel  => "Gimp procedure exists in pdb ?",
    :imagetypes => nil,
    :params     => [],
    :results    => []
) do |run_mode|
    include PDB::Access

    r1 = pdb_proc_exists("gimp-edit-fill")
    r2 = pdb_proc_exists(:gimp_edit_fill)
    r3 = !pdb_proc_exists("gimp-edit-dummy")
    r4 = !pdb_proc_exists(:gimp_edit_dummy)
    message (r1 and r2 and r3 and r4) ? "Success" : "Failure"
end

menu_register("ruby-fu-test-gimp_pdb_proc_exists", "<Image>/Filters/Ruby-Fu_Toolbox/Test")


register(
    :name       => "ruby-fu-test-gimp_pdb_getset_data",
    :blurb      => "...",
    :help       => "",
    :author     => nil,
    :copyright  => nil,
    :date       => nil,
    :menulabel  => "Gimp serialize data",
    :imagetypes => nil,
    :params     => [],
    :results    => []
) do |run_mode|
    include PDB::Access

    pdb_set_data("testdata", [123, "test", 6.025])
    rdata = pdb_get_data("testdata")
    message rdata == [123, "test", 6.025] ? "Success" : "Failure"
end

menu_register("ruby-fu-test-gimp_pdb_getset_data", "<Image>/Filters/Ruby-Fu_Toolbox/Test")
