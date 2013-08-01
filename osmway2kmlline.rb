# osmway2kmlline
# Converts an Open Street Maps XML file containing way information
# to a KML file containing LineStrings.
# 
# Iterates over all arguments and treats each as a file. Reports an
# error if a file is not found.
# 
# Can be called on a directory if -d <directory> is used instead of
# file name arguments

require 'nokogiri'

# If called with -d flag treat second argument as a directory
if (ARGV[0] == '-d')
    args = Dir.entries(ARGV[1])
    # Remove special directory symbols
    args.remove('.')
    args.remove('..')
else
    # Treat each argument as a filename
    args = ARGV
end

puts args

# Iterate over each file, opening, extracting way information and writing
# a .kml file containing polyline information.
args.each do |inputFileName|
    # Check file exists
    if File::exist?(inputFileName)
        # Open file
        File.open(inputFileName) do |f|
            # Parse document
            doc = Nokogiri::XML(f)

            # Build a hash of all nodes in this document as id => (lat lng) pair
            nodes = Hash.new

            doc.xpath('//node').each do |node|
                # Store each node as a hash pair {:lat,:lng}
                # Use to_sym to optimise indexing as id is not mutable
                nodes[node.attr('id').to_sym] = { :lat => node.attr('lat'), :lon => node.attr('lon') }
            end

            # Create a new KML document
            kml = Nokogiri::XML::Builder.new do |xml|

                xml.kml('xmlns' => 'http://www.opengis.net/kml/2.2') do

                    xml.Document do

                        # Iterate over each way, creating a linestring from
                        # the referenced nodes
                        doc.xpath('//way').each do |way|
                            linestring = ''
                            way.xpath('./nd').each do |nodeReference|
                                # Fetch the referenced node
                                node = nodes[nodeReference.attr('ref').to_sym]
                                # Concatenate node values into linestring
                                linestring += node[:lon] + ',' + node[:lat] + ',0 '
                            end

                            # Create a Placemark for this way
                            xml.Placemark {
                                # Set the Placemark name to Way + Way ID
                                xml.name_ 'Way ' + way.attr('id')
                                xml.LineString {
                                    xml.coordinates_ linestring
                                }
                            }

                        end

                    end

                end

            end

            # Append .kml to original filename and write output
            File.open(inputFileName + '.kml', 'w') {|f| f.write(kml.to_xml) }

        end
    else
        # Write an error indicating file does not exist
        puts 'Error: File not found "' + inputFileName + '"'
    end
end