#!/usr/bin/perl
#
# Perl script to remove some unnecessary .json tags and update some others

use strict;
use warnings;
use JSON;
use File::Find;
use Term::ReadLine;

my $term = Term::ReadLine->new('JSON Editor');

# Find all JSON files in the current directory and subdirectories
sub process_directory {
    my $dir = shift || '.';  # Default to current directory if none specified
    
    find(
        {
            wanted => sub {
                return unless -f $_ && $_ =~ /\.json$/;
                process_file($_);
            },
            no_chdir => 1,
        },
        $dir
    );
}

sub process_file {
    my $file = shift;
    
    print "Processing $file...\n";
    
    # Read the original file content
    open my $fh, '<', $file or die "Cannot open $file: $!";
    my $original_content = do { local $/; <$fh> };
    close $fh;
    
    # Parse JSON for processing logic
    my $json;
    eval {
        $json = decode_json($original_content);
    };
    if ($@) {
        print "Error parsing JSON in $file: $@\n";
        return;
    }
    
    # Verify we got a hash reference
    if (!defined $json || ref($json) ne 'HASH') {
        print "Warning: JSON in $file did not parse to a hash object, skipping...\n";
        return;
    }
    
    # Start with original content
    my $new_content = $original_content;
    
    # 1. Remove all instances of "nchars"
    $new_content = remove_nchars_from_content($new_content);
    
    # 2. Process lifetime field and set decade
    $new_content = process_lifetime_in_content($new_content, $json, $file);
    
    # 3. Add gofsidebar if needed
    $new_content = add_gofsidebar_to_content($new_content, $json);
    
    # 4. Fix ndash spacing between numbers
    $new_content = fix_ndash_in_content($new_content);
    
    # Write the modified content
    open $fh, '>', $file or die "Cannot write to $file: $!";
    print $fh $new_content;
    close $fh;
    
    print "Completed processing $file\n";
}

# Function to remove nchars from content
sub remove_nchars_from_content {
    my $content = shift;
    
    # Remove "nchars" field and its value, handling various formats
    # This handles: "nchars": value, (with comma)
    $content =~ s/"nchars"\s*:\s*[^,\}\]]+,\s*//g;
    # This handles: "nchars": value} or "nchars": value] (without comma at end)
    $content =~ s/,\s*"nchars"\s*:\s*[^,\}\]]+//g;
    # This handles standalone nchars (unlikely but just in case)
    $content =~ s/"nchars"\s*:\s*[^,\}\]]+//g;
    
    print "  Removed nchars fields\n";
    return $content;
}

# Function to process lifetime and add decade
sub process_lifetime_in_content {
    my ($content, $json, $file) = @_;
    
    # Verify $json is a hash reference
    if (!defined $json || ref($json) ne 'HASH') {
        print "  Warning: Cannot process lifetime - invalid JSON structure\n";
        return $content;
    }
    
    # Check if decade already exists
    if ($content =~ /"decade"\s*:/) {
        print "  Decade already exists, skipping...\n";
        return $content;
    }
    
    my $decade_to_add;
    
    if (exists $json->{lifetime} && defined $json->{lifetime}) {
        my $lifetime = $json->{lifetime};
        
        # Extract year from lifetime field
        if ($lifetime =~ /^(?:[0-9]{1,2}\s+)?[A-Za-z]{3}\s+([0-9]{4})&ndash;/) {
            my $year = $1;
            $decade_to_add = int($year / 10) * 10;
            print "  Set decade to $decade_to_add based on lifetime: $lifetime\n";
        }
        else {
            print "  Lifetime field doesn't match expected format in $file: '$lifetime'\n";
            my $input_decade = $term->readline("  Enter decade for $file (YYYY): ");
            if ($input_decade && $input_decade =~ /^[0-9]{4}$/) {
                $decade_to_add = int($input_decade);
                print "  Manually set decade to $decade_to_add\n";
            }
            else {
                print "  Invalid decade format, skipping...\n";
                return $content;
            }
        }
    }
    else {
        print "  No lifetime field found in $file\n";
        my $input_decade = $term->readline("  Enter decade for $file (YYYY): ");
        if ($input_decade && $input_decade =~ /^[0-9]{4}$/) {
            $decade_to_add = int($input_decade);
            print "  Manually set decade to $decade_to_add\n";
        }
        else {
            print "  Invalid decade format, skipping...\n";
            return $content;
        }
    }
    
    # Add decade field to the JSON content
    if (defined $decade_to_add) {
        # Try to add decade near lifetime field if it exists
        if ($content =~ s/("lifetime"\s*:\s*"[^"]*")/  "decade": $decade_to_add,\n  $1/) {
            # Successfully added near lifetime
        }
        # Otherwise, add at the beginning of the main object
        elsif ($content =~ s/\{\s*\n?/{\n  "decade": $decade_to_add,\n/) {
            # Successfully added at beginning
        }
        # Fallback: add after opening brace
        else {
            $content =~ s/\{/{\n  "decade": $decade_to_add,/;
        }
    }
    
    return $content;
}

# Function to add gofsidebar if needed
sub add_gofsidebar_to_content {
    my ($content, $json) = @_;
    
    # Verify $json is a hash reference
    if (!defined $json || ref($json) ne 'HASH') {
        print "  Warning: Cannot process gofsidebar - invalid JSON structure\n";
        return $content;
    }
    
    # Check if gofsidebar already exists
    if ($content =~ /"gofsidebar"\s*:/) {
        return $content;
    }
    
    # Check if gofheader or goffooter exists in the parsed JSON
    if ((exists $json->{gofheader} && defined $json->{gofheader}) || 
        (exists $json->{goffooter} && defined $json->{goffooter})) {
        
        # Add gofsidebar field
        if ($content =~ s/("gof(?:header|footer)"\s*:\s*"[^"]*")/  "gofsidebar": "Past",\n  $1/) {
            print "  Added gofsidebar: Past\n";
        }
        # Fallback: add at beginning
        elsif ($content =~ s/\{\s*\n?/{\n  "gofsidebar": "Past",\n/) {
            print "  Added gofsidebar: Past\n";
        }
    }
    
    return $content;
}

# Function to fix ndash spacing in content
sub fix_ndash_in_content {
    my $content = shift;
    
    # Replace " &ndash; " with "&ndash;" only when between numbers
    my $changes = ($content =~ s/(\d)\s+&ndash;\s+(\d)/$1&ndash;$2/g);
    
    if ($changes) {
        print "  Fixed $changes ndash spacing issues\n";
    }
    
    return $content;
}

# Main execution
my $directory = $ARGV[0] || '.';
print "Starting JSON bulk edit in directory: $directory\n";
process_directory($directory);
print "All processing complete.\n";
