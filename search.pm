#!/usr/intel/bin/perl5.14.1

package search_tool;
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Term::ANSIColor;


sub main
{
    my $unittest;
    my $text_file;
    my @search_words;
    GetOptions
	("-unittest" => \$unittest,
	 "-text_file=s" => \$text_file,
	 "-words=s{1,}" => \@search_words) or die "error in command line args";

    if($unittest)
    {
	run_unit_tests();
    }
    else
    {
	my %locations = read_file($text_file, @search_words);
	my %matches = compare_word_locations(\%locations, \@search_words);
	print_matches_found($text_file, \%matches);
    }
}
main() unless caller;


sub read_file
{
    my ($text_file, @search_words) = @_;
    open(FILE, "<$text_file") or die "failed to open $text_file $!";
    my @lines = <FILE>;
    my $index = 0;
    my %locations;
    foreach my $search_word (@search_words)
    {
	$index = 0;
	foreach my $line (@lines)
	{
	    chomp $line;
	    my @words = split(" ", $line);
	    foreach my $word (@words)
	    {
		if($word =~ m/\A\W*$search_word\W*\Z/i)
		{
		    push (@{$locations{$search_word}}, $index);
		}
		$index++;
	    }
	}
	if(!$locations{$search_word}[0])
	{
	    push (@{$locations{$search_word}}, "");
	    die "couldnt find the word: $search_word";
	}
    }
    close(FILE);
    return %locations;
}


sub compare_word_locations
{
    my %locations = %{shift @_}; 
    my @search_words = @{shift @_};
    my %matches;
    my $index = 0;
    foreach my $locations_first_word (@{$locations{$search_words[0]}})
    {
	foreach my $locations_second_word (@{$locations{$search_words[1]}})
	{
	    foreach my $locations_third_word (@{$locations{$search_words[2]}})
	    {
		my $first_and_second = abs($locations_first_word - $locations_second_word);
		my $second_and_third = abs($locations_third_word - $locations_second_word);
		my $first_and_third = abs($locations_third_word - $locations_first_word);
		if($second_and_third < 100 && $first_and_third < 100 && $first_and_second < 100)
		{
		    push(@{$matches{$index}}, $locations_third_word);
		    push(@{$matches{$index}}, $locations_second_word);
		    push(@{$matches{$index}}, $locations_first_word); 
		    $index++;
		}
	    }
	}
    } 
    return %matches;
}


sub print_matches_found
{
    
    my $text_file = shift @_;
    my %matches = %{shift @_};
    open(FILE, "<$text_file") or die "failed to open $text_file $!";
    my @lines = <FILE>;
    my $index = 0;
    my $flag = 0;
    my @array_of_sorted;
    my $array_index = 0;
    my %sorted_matches;
    my %doubly_sorted_matches;
    foreach my $key (keys%matches)
    {
        @array_of_sorted = sort{$a<=>$b}@{$matches{$key}};
	@{$sorted_matches{$array_of_sorted[0]}} = @array_of_sorted;#losing some here but thats ok
    }

    my @array_of_keys = sort{$a<=>$b}keys%sorted_matches;
    #print Dumper \%sorted_matches;
    foreach my $line (@lines)
    {
    	my @words = split(" ", $line);
    	foreach my $word (@words)
    	{
	    my $lesser_val = 0;
	    my $greater_val = 0;
	    if(exists($array_of_keys[$array_index]))
	    {
	    	$lesser_val = @{$sorted_matches{$array_of_keys[$array_index]}}[0];
	    	$greater_val = @{$sorted_matches{$array_of_keys[$array_index]}}[2];
	    }
    	    if($index >= $lesser_val && $index <= $greater_val)
    	    {
    	    	print colored['bold blue'],  "$word ";
    	    }
    	    else
    	    {
    	    	print "$word ";
    	    }
    	    if($index == $greater_val)
    	    {
    	    	$array_index++;
		my $flag = 1;
		while($flag)
		{
		    if(exists($array_of_keys[$array_index]))
		    {
			if(@{$sorted_matches{$array_of_keys[$array_index]}}[2] <= $index)
			{
			    $array_index++;
			}
			else
			{
			    $flag = 0;
			}
		    }
		    else
		    {
			$flag = 0;
		    }
		}
    	    }
    	    $index++;
    	}
    }
    close(FILE);
    print "\n";
}


sub run_unit_tests 
{

}


1;

