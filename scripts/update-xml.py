#!/usr/bin/env python3
import xml.etree.ElementTree as ET
import os
import sys

def add_release_notes_link(xml_file, notes_path="./release.md"):
    """
    Add a sparkle:releaseNotesLink element to each item in the appcast.xml file
    if it doesn't already have one.
    
    Args:
        xml_file (str): Path to the appcast.xml file
        notes_path (str): Path to the release notes file
    """
    # Register the namespace
    ET.register_namespace('sparkle', 'http://www.andymatuschak.org/xml-namespaces/sparkle')
    
    # Parse the XML file
    tree = ET.parse(xml_file)
    root = tree.getroot()
    
    # Define the namespace map
    namespaces = {'sparkle': 'http://www.andymatuschak.org/xml-namespaces/sparkle'}
    
    # Flag to track if any changes were made
    changes_made = False
    
    # Find all items
    channel = root.find('channel')
    if channel is not None:
        for item in channel.findall('item'):
            # Check if the item already has a releaseNotesLink
            release_notes_link = item.find('.//sparkle:releaseNotesLink', namespaces)
            
            if release_notes_link is None:
                # Create new releaseNotesLink element
                release_notes_link = ET.Element('{http://www.andymatuschak.org/xml-namespaces/sparkle}releaseNotesLink')
                release_notes_link.text = notes_path
                
                # Add it after title and pubDate
                title = item.find('title')
                pubDate = item.find('pubDate')
                
                # Find the insertion point - after pubDate if it exists, otherwise after title
                if pubDate is not None:
                    # Find index of pubDate and insert after it
                    index = list(item).index(pubDate) + 1
                elif title is not None:
                    # Find index of title and insert after it
                    index = list(item).index(title) + 1
                else:
                    # Insert at the beginning if neither exists
                    index = 0
                
                item.insert(index, release_notes_link)
                changes_made = True
    
    if changes_made:
        # Write the modified XML to the file directly without creating a backup
        tree.write(xml_file, encoding='utf-8', xml_declaration=True)
        print(f"Updated {xml_file} with release notes links")
    else:
        print("All items already have release notes links. No changes made.")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        xml_file = sys.argv[1]
        notes_path = sys.argv[2] if len(sys.argv) > 2 else "./release_notes.md"
        add_release_notes_link(xml_file, notes_path)
    else:
        print("Usage: python update-xml.py <path_to_appcast.xml> [path_to_release_notes]")
        print("Example: python update-xml.py ./appcast.xml ./release_notes.md")
        sys.exit(1)
