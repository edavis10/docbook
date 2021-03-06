module Docbook
  module Adapters
      
    module Fo
      # Interface for FO-PDF processors, for taking FO output created by the XML processor and converting it to various formats. This class
      # should be extended to control the various formats.
      module Fop
    
        # initialize the object and set the extensions and output type. Defaults to PDF
        def initialize(args = {})
          super
          @xsl_extension = "fo"

        end
    
        # build up the options for FOP
        def fop_options
          fop_cp      = "#{self.root}/fop/avalon-framework-4.2.0.jar;"
          fop_cp << "#{self.root}/jars/batik-all-1.7.jar;"
          fop_cp << "#{self.root}/jars/commons-io-1.3.1.jar;"
          fop_cp << "#{self.root}/jars/commons-logging-1.0.4.jar;"
          fop_cp << "#{self.root}/jars/fop-hyph.jar;"
          fop_cp << "#{self.root}/jars/fop.jar;"
          fop_cp << "#{self.root}/jars/serializer-2.7.0.jar;"
          fop_cp << "#{self.root}/jars/xalan-2.7.0.jar;"
          fop_cp << "#{self.root}/jars/xercesImpl-2.7.1.jar;"
          fop_cp << "#{self.root}/jars/xml-apis-1.3.04.jar;"
          fop_cp << "#{self.root}/jars/xmlgraphics-commons-1.4.jar;"
          fop_cp
        end
    
        # Create the command to launch FOP
        def fop_command  
          cmd = "java -Xmx512m -Xss1024K -cp #{fop_options} org.apache.fop.cli.Main -fo #{self.file}.fo -#{@output} #{self.file}.#{@output}"

          cmd.gsub!(";",":") unless @windows
          cmd
        end
    
        def before_render
          xsl_path = @windows ? self.root : self.root.lchop
      
          fo_xml = %Q{<?xml version='1.0'?>

          <!-- DO NOT CHANGE THIS FILE. IT IS AUTOGENERATED BY THE SHORT-ATTENTION-SPAN-DOCBOOK CHAIN -->

          <xsl:stylesheet 
             xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
             xmlns:fo="http://www.w3.org/1999/XSL/Format"
             xmlns:xslthl="http://xslthl.sf.net"
             xmlns:d="http://docbook.org/ns/docbook"
          >
            <!-- Import the original FO stylesheet -->
            <xsl:import href="file:///#{xsl_path}/xsl/fo/docbook.xsl"/>
            <xsl:import href="file:///#{xsl_path}/xsl/fo/highlight.xsl"/>
      
            <!-- FOP -->
            <!-- PDF bookmarking support -->
            <xsl:param name="fop1.extensions" select="1" />
          }
      
          fo_xml << %Q{
            <xsl:param name="show.comments" select="1"></xsl:param>
            <xsl:param name="draft.watermark.image">http://docbook.sourceforge.net/release/images/draft.png</xsl:param>
            <xsl:param name="draft.mode">yes</xsl:param>
          } if @draft
      
          fo_xml << "</xsl:stylesheet>"
      
          File.open("xsl/fo.xml", "w") do |f|
            f << fo_xml
          end
        end
     
        # Callback to build the final file after the XML-FO rendering occurs
        def after_render
          if File.exists?("#{self.file}.fo")
            puts "Building #{@output}"
            print_debug(self.fop_command)
            `#{self.fop_command}`
    
            puts "Cleaning up"
            FileUtils.rm "#{self.file}.fo"
            
            add_cover if self.respond_to?(:add_cover)
            
          else
            puts "FO processing halted - missing #{self.file}.fo file."
          end
        end
        
      end
    end
  end
end