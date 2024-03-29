require 'nokogiri'

module ApexMarkup
  def controller
    doc = Nokogiri::HTML body
    apex_page = doc.css container_tag
    if apex_page && !apex_page.empty?
      apex_page = apex_page[0]
      ctrl_attr = apex_page.attributes["controller"]
      if ctrl_attr
        ctrl_attr.value
      end
    end
  end

  def extensions
    doc = Nokogiri::HTML body
    apex_page = doc.css container_tag
    ret = []
    if apex_page && !apex_page.empty?
      apex_page = apex_page[0]
      ctrl_attr = apex_page.attributes["extensions"]
      if ctrl_attr
        ret = ctrl_attr.value.split ","
      end
    end
    ret
  end
end