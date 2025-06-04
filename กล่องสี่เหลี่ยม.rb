# my_box_interactive_placement_tool.rb
# โหลดไฟล์นี้ใน SketchUp (Window > Extension Manager > Install Extension)

require 'sketchup.rb'

module MyExtensions
  module BoxInteractivePlacementTool

    class MyBoxInteractivePlacementTool
      attr_accessor :component_definition, :preview_instance, :layer_object
      attr_accessor :width, :length, :height, :component_name, :layer_name

      def activate
        # 1. เรียก Dialog Box เพื่อรับค่าจากผู้ใช้ก่อน
        unless get_dimensions_from_user
          # หากผู้ใช้กด Cancel หรือป้อนค่าไม่ถูกต้อง ให้ยกเลิกเครื่องมือ
          Sketchup.active_model.select_tool(nil)
          return
        end

        # 2. เมื่อได้รับค่าแล้ว ให้สร้าง Component Definition และ Preview Instance
        begin
          model = Sketchup.active_model

          # --- จัดการ Layer ---
          @layer_object = model.layers[@layer_name]
          unless @layer_object
            @layer_object = model.layers.add(@layer_name)
          end

          # --- จัดการ Component Definition ---
          @component_definition = model.definitions[@component_name]
          unless @component_definition
            @component_definition = model.definitions.add(@component_name)
          end

          # ล้าง entities เดิมออกไปก่อน หากมีการสร้างใหม่เพื่อแก้ไขขนาด
          # (ในกรณีที่ definition เดิมมีอยู่แล้วและเราต้องการสร้างใหม่ทับ)
          entities_to_clear = @component_definition.entities
          if entities_to_clear.count > 0 && @component_definition.count_used_instances > 0
            entities_to_clear.clear!
          end

          # สร้าง Geometry ภายใน Component Definition
          entities = @component_definition.entities

          # 1. สร้าง Base Face (สี่เหลี่ยมฐาน) ในพื้นที่ของ Component Definition
          p1_def = Geom::Point3d.new(0, 0, 0) # เริ่มต้นที่ (0,0,0) สำหรับ Component Definition
          p2_def = Geom::Point3d.new(@width, 0, 0)
          p3_def = Geom::Point3d.new(@width, @length, 0)
          p4_def = Geom::Point3d.new(0, @length, 0)

          pts_def = [p1_def, p2_def, p3_def, p4_def]
          face_def = entities.add_face(pts_def)

          if face_def.normal.z < 0
            face_def.reverse!
          end

          # 2. Extrude (ดัน) Face ขึ้นไปตามความสูงที่กำหนด
          face_def.pushpull(@height)

          # สร้าง Preview Instance ที่ตำแหน่งเริ่มต้น (0,0,0) ก่อน
          # จะถูกย้ายใน onMouseMove
          @preview_instance = model.entities.add_instance(@component_definition, Geom::Transformation.new)
          @preview_instance.layer = @layer_object # กำหนด layer ให้ preview instance ด้วย

          Sketchup::set_status_text "เลื่อนเมาส์เพื่อวางกล่อง คลิกเพื่อยืนยัน"

        rescue Exception => e
          UI.messagebox("เกิดข้อผิดพลาดในการเตรียมการสร้างกล่อง: #{e.message}", MB_OK)
          Sketchup.active_model.select_tool(nil) # ยกเลิกเครื่องมือ
        end
      end

      def deactivate(view)
        # ตรวจสอบและลบ Preview Instance ออกเมื่อเครื่องมือถูกยกเลิก
        # ถ้าไม่ได้ลบ จะมีกล่องค้างอยู่ในโมเดล
        if @preview_instance && @preview_instance.valid?
          @preview_instance.erase!
          @preview_instance = nil
        end
        Sketchup::set_status_text ""
        view.invalidate # บังคับให้ SketchUp วาดใหม่เพื่อลบ Preview
      end

      # ฟังก์ชันรับค่าจากผู้ใช้
      def get_dimensions_from_user
        prompts = ["ความกว้าง:", "ความยาว:", "ความสูง:", "ชื่อ Component:", "ชื่อ Layer:"]
        defaults = ["1m", "1m", "1m", "MyBoxComponent", "Boxes Layer"]
        title = "ตั้งค่ากล่องสี่เหลี่ยม"

        input = UI.inputbox(prompts, defaults, title)

        return false unless input # ผู้ใช้กด Cancel

        @width_str, @length_str, @height_str, @component_name, @layer_name = input

        # แปลงค่า String ให้เป็นหน่วยความยาวของ SketchUp
        begin
          @width = @width_str.to_l
          @length = @length_str.to_l
          @height = @height_str.to_l
        rescue
          UI.messagebox("ค่าที่ป้อนไม่ถูกต้อง กรุณาป้อนตัวเลขพร้อมหน่วย (เช่น 1m, 100cm)", MB_OK)
          return false
        end

        if @width <= 0 || @length <= 0 || @height <= 0
          UI.messagebox("ความกว้าง ความยาว และความสูง ต้องเป็นค่าบวก", MB_OK)
          return false
        end

        if @component_name.strip.empty?
          UI.messagebox("กรุณาระบุชื่อ Component", MB_OK)
          return false
        end

        if @layer_name.strip.empty?
          UI.messagebox("กรุณาระบุชื่อ Layer", MB_OK)
          return false
        end

        return true # สำเร็จ
      end

      def onMouseMove(flags, x, y, view)
        # 3. เลื่อนเมาส์เพื่อวางกล่อง Preview
        if @preview_instance # ตรวจสอบว่ามี preview instance อยู่หรือไม่
          ip = view.inputpoint x, y # รับจุด 3D ใต้เมาส์
          if ip.valid?
            # สร้าง Transformation เพื่อย้าย Preview Instance ไปที่จุดที่เมาส์อยู่
            transform = Geom::Transformation.new(ip.position)
            @preview_instance.transformation = transform
          end
          view.invalidate # บังคับให้ SketchUp วาดใหม่
        end
      end

      def onLButtonDown(flags, x, y, view)
        # 4. คลิกเพื่อยืนยันการวาง
        if @preview_instance && @preview_instance.valid?
          model = Sketchup.active_model
          model.start_operation("วางกล่อง Component", true)

          begin
            # สร้าง Component Instance ถาวร ณ ตำแหน่งของ Preview Instance
            final_transform = @preview_instance.transformation
            final_instance = model.entities.add_instance(@component_definition, final_transform)
            final_instance.layer = @layer_object

            # ลบ Preview Instance ออก
            @preview_instance.erase!
            @preview_instance = nil

            # เลือก Instance ที่สร้างขึ้นมา
            model.selection.clear
            model.selection.add(final_instance)

          rescue Exception => e
            UI.messagebox("เกิดข้อผิดพลาดในการวางกล่อง: #{e.message}", MB_OK)
            model.abort_operation
          ensure
            model.commit_operation
          end

          model.select_tool(nil) # ยกเลิกเครื่องมือ
        end
      end

      # ไม่ต้องมี draw method สำหรับ Component Instance เพราะ SketchUp จะวาดให้เอง

    end # class MyBoxInteractivePlacementTool

    # ส่วนนี้ใช้สำหรับเพิ่มคำสั่งในเมนู Extensions ของ SketchUp
    unless file_loaded?(__FILE__)
      menu = UI.menu("Extensions")
      menu.add_item("สร้างกล่อง (วางด้วยเมาส์)") {
        Sketchup.active_model.select_tool(MyBoxInteractivePlacementTool.new)
      }
      file_loaded(__FILE__)
    end

  end # module BoxInteractivePlacementTool
end # module MyExtensions