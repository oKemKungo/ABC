require 'sketchup.rb'
require 'json' # จำเป็นสำหรับการแปลงข้อมูลเป็น JSON

module MyDataExtension

  # สร้าง HTML Dialog
  def self.show_data_dialog(data_type = :all)
    options = {
      :dialog_title => "ข้อมูลชิ้นงานในโมเดล",
      :preferences_key => "MyDataExtension",
      :width => 700,
      :height => 500,
      :resizable => true
    }

    @dialog = UI::HtmlDialog.new(options)
    html_file = File.join(__dir__, 'data_display.html')
    @dialog.set_file(html_file)
    @dialog.show
    # @dialog.show_dev_tools # <<< บรรทัดนี้ถูกคอมเมนต์ไว้เพื่อหลีกเลี่ยงข้อผิดพลาดใน SketchUp บางเวอร์ชัน

    # Callback เมื่อ HTML Dialog ร้องขอข้อมูล
    @dialog.add_action_callback("requestData") do |action_context, requested_data_type|
      puts "Ruby: Received requestData callback from HTML Dialog with type: #{requested_data_type}."
      begin
        # get_processed_data จะ return เฉพาะ data array (ที่มีหน่วยแล้ว)
        data = get_processed_data(requested_data_type.to_sym) 
        unit_symbol = get_unit_symbol # ดึงสัญลักษณ์หน่วยวัดปัจจุบันแยกต่างหาก

        payload = {
          data: data,
          unit_symbol: unit_symbol # ส่งสัญลักษณ์หน่วยวัดไปด้วย
        }

        puts "Ruby: Data prepared, #{data.length} rows found."
        @dialog.execute_script("displayData(#{payload.to_json});")
        puts "Ruby: Data sent to HTML Dialog."
      rescue => e
        puts "Ruby Error in requestData callback: #{e.message}"
        puts e.backtrace.join("\n")
        @dialog.execute_script("displayData({data: [], unit_symbol: ''}); console.error('Ruby Error: #{e.message.gsub("'", "\\'") }');")
      end
    end

    # Callback สำหรับการสร้าง Tag ใหม่
    @dialog.add_action_callback("createTag") do |action_context, tag_name|
      puts "Ruby: Received createTag callback for tag: #{tag_name}"
      model = Sketchup.active_model
      # Start an operation for undo
      model.start_operation("Create New Tag", true)
      begin
        if tag_name.nil? || tag_name.empty?
          @dialog.execute_script("alert('ชื่อ Tag ต้องไม่ว่างเปล่า');")
        elsif model.layers[tag_name]
          @dialog.execute_script("alert('Tag \\'#{tag_name}\\' มีอยู่แล้ว');")
        else
          model.layers.add(tag_name)
          @dialog.execute_script("alert('Tag \\'#{tag_name}\\' สร้างสำเร็จ!');")
        end
      rescue => e
        puts "Ruby Error creating tag: #{e.message}"
        @dialog.execute_script("alert('เกิดข้อผิดพลาดในการสร้าง Tag: #{e.message.gsub("'", "\\'") }');")
      ensure
        model.commit_operation # Commit or abort the operation
        # Re-request data to update the table
        @dialog.execute_script("requestDataFromRuby(document.getElementById('dataTypeSelector').value);")
      end
    end

    # Callback สำหรับการลบ Tag ที่เลือก
    @dialog.add_action_callback("deleteTags") do |action_context, tag_names|
      puts "Ruby: Received deleteTags callback for tags: #{tag_names.inspect}"
      model = Sketchup.active_model
      layer0 = model.layers[0] # "Layer0" is typically the default layer

      if layer0.nil?
        @dialog.execute_script("alert('Layer0 (Default Layer) ไม่พบ. ไม่สามารถดำเนินการลบได้');")
        return
      end

      # เพิ่มการยืนยันการลบ
      confirm_message = "คุณต้องการลบ Tag เหล่านี้จริงหรือไม่:\n" + tag_names.join("\n")
      result = UI.messagebox(confirm_message, MB_YESNO, "ยืนยันการลบ Tag")

      if result == IDNO # ถ้าผู้ใช้กด 'No'
        @dialog.execute_script("alert('การลบ Tag ถูกยกเลิก.');")
        puts "Ruby: Tag deletion cancelled by user."
        return 
      end

      model.start_operation("Delete Selected Tags", true)
      begin
        tag_names.each do |tag_name|
          layer_to_delete = model.layers[tag_name]
          if layer_to_delete.nil?
            @dialog.execute_script("alert('ไม่พบ Tag \\'#{tag_name}\\'');")
            next
          end
          if layer_to_delete == layer0
            @dialog.execute_script("alert('ไม่สามารถลบ Layer0 ได้');")
            next
          end

          model.layers.remove(layer_to_delete, layer0)
          puts "Ruby: Tag '#{tag_name}' deleted."
        end
        @dialog.execute_script("alert('Tag ที่เลือกถูกลบสำเร็จ!');")
      rescue => e
        puts "Ruby Error deleting tags: #{e.message}"
        @dialog.execute_script("alert('เกิดข้อผิดพลาดในการลบ Tag: #{e.message.gsub("'", "\\'") }');")
      ensure
        model.commit_operation 
        @dialog.execute_script("requestDataFromRuby(document.getElementById('dataTypeSelector').value);")
      end
    end
  end # method show_data_dialog

  # เมธอดหลักสำหรับดึงและประมวลผลข้อมูล
  def self.get_processed_data(data_type)
    data = []
    case data_type
    when :selection
      data = get_selection_data
    when :material
      data = get_material_data
    when :tag
      data = get_tag_data
    else # Default to selection data if type is unknown or :all
      data = get_selection_data
    end
    data
  end

  # ดึงข้อมูลจาก Group และ ComponentInstance ในโมเดล
  def self.get_selection_data
    model = Sketchup.active_model
    data = []
    unit_symbol = get_unit_symbol # ดึงหน่วยสัญลักษณ์
    conversion_factor_for_length = get_length_conversion_factor_from_inches # ดึงตัวแปลง

    model.entities.each do |entity|
      next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)

      name = ""
      if entity.is_a?(Sketchup::ComponentInstance)
        name = entity.definition.name.empty? ? "Unnamed Component" : entity.definition.name
      else
        name = entity.name.empty? ? "Unnamed Group" : entity.name
      end

      type_label = ""
      if entity.is_a?(Sketchup::ComponentInstance)
        type_label = "Component" 
      elsif entity.is_a?(Sketchup::Group)
        type_label = "Group"
      end

      # Calculate volume
      volume_in_inches = 0.0
      if entity.is_a?(Sketchup::Group)
        if entity.manifold? 
          volume_in_inches = entity.volume
        else
          volume_in_inches = 0.0 
        end
      elsif entity.is_a?(Sketchup::ComponentInstance)
        if entity.definition.respond_to?(:volume) && entity.manifold? # ตรวจสอบ manifold ของ instance ด้วย
          volume_in_inches = entity.definition.volume 
        else
          volume_in_inches = 0.0
        end
      end

      # For Area and Length, iterate through inner entities
      area_in_inches = 0.0
      length_in_inches = 0.0

      inner_entities = entity.is_a?(Sketchup::ComponentInstance) ? entity.definition.entities : entity.entities
      inner_entities.grep(Sketchup::Face).each do |face|
        area_in_inches += face.area
      end

      inner_entities.grep(Sketchup::Edge).each do |edge|
        length_in_inches = [length_in_inches, edge.length].max 
      end

      data << {
        name: name,
        type: type_label, 
        # เรียกใช้ convert functions เพื่อให้ได้ string ที่มีหน่วยแล้ว
        area: convert_area(area_in_inches, conversion_factor_for_length, unit_symbol),
        volume: convert_volume(volume_in_inches, conversion_factor_for_length, unit_symbol),
        length: convert_length(length_in_inches, conversion_factor_for_length, unit_symbol)
      }
    end
    data
  end

  # ดึงข้อมูลจาก Material
  def self.get_material_data
    model = Sketchup.active_model
    data = []
    material_areas = Hash.new { |hash, key| hash[key] = { area: 0.0, volume: 0.0, length: 0.0 } }
    unit_symbol = get_unit_symbol
    conversion_factor_for_length = get_length_conversion_factor_from_inches

    # รวบรวมพื้นที่สำหรับ Material ทั้งหมด รวมถึง "No Material" จาก Face ที่ไม่มี Material
    model.entities.each do |entity|
      # Helper for recursive traversal to find all faces
      traverse_entities_for_material_area(entity, material_areas)
    end
    
    # เพิ่ม Material ที่มีอยู่ในโมเดลทั้งหมด
    model.materials.each do |material|
      next if material.name == "No Material" # Skip "No Material" explicitly
      name = material.display_name
      area = material_areas[name] ? material_areas[name][:area] : 0.0
      if area > 0
        data << {
          name: name,
          type: "Material",
          area: convert_area(area, conversion_factor_for_length, unit_symbol),
          volume: "0", 
          length: "0" 
        }
      end
    end
    data
  end

  # Helper method for get_material_data to recursively traverse entities
  def self.traverse_entities_for_material_area(entity, material_areas)
    puts "DEBUG: traverse_entities_for_material_area called for entity type: #{entity.class.name}"
    if entity.is_a?(Sketchup::Face)
      puts "DEBUG: Found a Face. Area: #{entity.area}. Material: #{entity.material.display_name if entity.material}"
      if entity.material
        mat_name = entity.material.display_name
        material_areas[mat_name][:area] += entity.area
        puts "DEBUG: Added area to material_areas for #{mat_name}. Current area: #{material_areas[mat_name][:area]}"
      else
        puts "DEBUG: Face has no material."
      end
      # Do not add "No Material" if there is no material
    elsif entity.is_a?(Sketchup::Group)
      puts "DEBUG: Entering Group: #{entity.name}"
      entity.entities.each { |e| traverse_entities_for_material_area(e, material_areas) }
      puts "DEBUG: Exiting Group: #{entity.name}"
    elsif entity.is_a?(Sketchup::ComponentInstance)
      puts "DEBUG: Entering ComponentInstance: #{entity.definition.name}"
      entity.definition.entities.each { |e| traverse_entities_for_material_area(e, material_areas) }
      puts "DEBUG: Exiting ComponentInstance: #{entity.definition.name}"
    end
  end

  # เมธอดช่วยสำหรับวนลูปซ้ำเพื่อดึงเอนทิตี้ทั้งหมดภายใน Group หรือ ComponentInstance
  # และรวบรวมข้อมูลตาม Tag ของเอนทิตี้เหล่านั้น
  def self.process_entities_for_tags(entities, tags_data, effective_parent_layer_name = "Layer0")
    entities.each do |entity|
      current_entity_layer_name = entity.respond_to?(:layer) && entity.layer ? entity.layer.name : "Layer0"
      
      # Determine the effective layer for this entity's contribution
      # If the entity is on Layer0, it inherits its parent's effective layer.
      # Otherwise, its own layer is the effective layer.
      effective_layer_for_contribution = (current_entity_layer_name == "Layer0") ? effective_parent_layer_name : current_entity_layer_name

      # Ensure the effective layer is in our tags_data hash if it's not Layer0
      unless effective_layer_for_contribution == "Layer0"
        tags_data[effective_layer_for_contribution] ||= { area: 0.0, volume: 0.0, length: 0.0 }
      end

      if entity.is_a?(Sketchup::Face)
        unless effective_layer_for_contribution == "Layer0"
          tags_data[effective_layer_for_contribution][:area] += entity.area
        end
      elsif entity.is_a?(Sketchup::Edge)
        unless effective_layer_for_contribution == "Layer0"
          tags_data[effective_layer_for_contribution][:length] += entity.length
        end
      elsif entity.is_a?(Sketchup::Group)
        # For Group, volume is associated with its own effective layer
        unless effective_layer_for_contribution == "Layer0"
          if entity.manifold?
            tags_data[effective_layer_for_contribution][:volume] += entity.volume
          end
        end
        # Recurse, passing the current effective layer as the parent layer for children
        process_entities_for_tags(entity.entities, tags_data, effective_layer_for_contribution)
      elsif entity.is_a?(Sketchup::ComponentInstance)
        # For ComponentInstance, volume is associated with its own effective layer
        unless effective_layer_for_contribution == "Layer0"
          if entity.manifold? && entity.definition.respond_to?(:volume)
            tags_data[effective_layer_for_contribution][:volume] += entity.definition.volume
          end
        end
        # Recurse, passing the current effective layer as the parent layer for children
        process_entities_for_tags(entity.definition.entities, tags_data, effective_layer_for_contribution)
      end
    end
  end


  # ดึงข้อมูลจาก Tag (Layer)
  def self.get_tag_data
    model = Sketchup.active_model
    data = []
    tags_data = Hash.new { |hash, key| hash[key] = { area: 0.0, volume: 0.0, length: 0.0 } }
    unit_symbol = get_unit_symbol
    conversion_factor_for_length = get_length_conversion_factor_from_inches

    # Initialize tags_data for all layers (except Layer0)
    # This ensures all existing tags are considered for potential display.
    model.layers.each do |layer|
      unless layer.name == "Layer0"
        tags_data[layer.name] = { area: 0.0, volume: 0.0, length: 0.0 }
      end
    end

    # เริ่มกระบวนการวนลูปซ้ำจากเอนทิตี้ระดับบนสุดของโมเดล
    process_entities_for_tags(model.entities, tags_data, "Layer0") # Initial call with "Layer0" as effective parent layer
    
    # กรองเฉพาะ Tag ที่มี Area, Volume, หรือ Length มากกว่า 0
    tags_data.each do |name, values|
      if values[:area] > 0 || values[:volume] > 0 || values[:length] > 0 
        data << {
          name: name,
          type: "Tag",
          area: convert_area(values[:area], conversion_factor_for_length, unit_symbol),
          volume: convert_volume(values[:volume], conversion_factor_for_length, unit_symbol),
          length: convert_length(values[:length], conversion_factor_for_length, unit_symbol)
        }
      end
    end
    data
  end

  # เมธอดช่วยในการแปลงหน่วยพื้นที่
  def self.convert_area(area_in_inches, conversion_factor_for_length, unit_symbol)
    if area_in_inches > 0
      area_converted = area_in_inches * (conversion_factor_for_length ** 2)
      return "#{area_converted.round(2)} #{unit_symbol}\u00B2" # Unicode for squared
    else
      return "0"
    end
  end

  # เมธอดช่วยในการแปลงหน่วยปริมาตร
  def self.convert_volume(volume_in_inches, conversion_factor_for_length, unit_symbol)
    if volume_in_inches > 0
      volume_converted = volume_in_inches * (conversion_factor_for_length ** 3)
      return "#{volume_converted.round(2)} #{unit_symbol}\u00B3" # Unicode for cubed
    else
      return "0"
    end
  end

  # เมธอดช่วยในการแปลงหน่วยความยาว
  def self.convert_length(length_in_inches, conversion_factor_for_length, unit_symbol)
    if length_in_inches > 0
      length_converted = length_in_inches * conversion_factor_for_length
      return "#{length_converted.round(2)} #{unit_symbol}"
    else
      return "0"
    end
  end

  # เมธอดช่วยดึงหน่วยที่ใช้งานอยู่ในโมเดลปัจจุบัน
  def self.get_unit_symbol
    model = Sketchup.active_model
    manager = model.options["UnitsOptions"]
    length_unit = manager["LengthUnit"]

    case length_unit
    when 0 then "in" # Sketchup::Inches
    when 1 then "ft" # Sketchup::Feet
    when 2 then "mm" # Sketchup::Millimeters
    when 3 then "cm" # Sketchup::Centimeters
    when 4 then "m"  # Sketchup::Meters
    else "in" # Default to inches if unknown
    end
  end

  # เมธอดช่วยดึงตัวประกอบการแปลงจากนิ้วไปยังหน่วยปัจจุบัน
  def self.get_length_conversion_factor_from_inches
    model = Sketchup.active_model
    manager = model.options["UnitsOptions"]
    length_unit = manager["LengthUnit"]

    case length_unit
    when 0 then 1.0 # Sketchup::Inches
    when 1 then 1.0 / 12.0 # Sketchup::Feet
    when 2 then 25.4 # Sketchup::Millimeters
    when 3 then 2.54 # Sketchup::Centimeters
    when 4 then 0.0254 # Sketchup::Meters
    else 1.0 # Default to inches
    end
  end

  # เพิ่มคำสั่งในเมนู Extensions
  unless file_loaded?(__FILE__)
    menu = UI.menu("Extensions")
    menu.add_item("📊 Data Display") do
      self.show_data_dialog
    end
    file_loaded(__FILE__)
  end

end # module MyDataExtension