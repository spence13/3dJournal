#!/usr/intel/bin/perl5.14.1

package check_dir_permissions;
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;


sub main
{
    my $unittest;
    my $dir_path;
    my @groups;
    GetOptions
	("-unittest" => \$unittest,
	 "-path=s" => \$dir_path,
	 "-groups=s{1,}" => \@groups) or die "error in command line args";

    if($unittest)
    {
	run_unit_tests($dir_path, @groups);
    }
    else
    {
	get_forbidden_dirs($dir_path, @groups);
	get_globally_readable_dirs($dir_path, @groups);	
    }
}
main() unless caller;


sub get_dir_permissions
{
    my $dir_path =  shift @_;
    my $permissions = (stat($dir_path))[2] or die "not a correct path given";
    my $oct_permissions = sprintf "%04o", $permissions & 07777;
    return $oct_permissions;
}

sub get_owners_group_name
{
    my $dir_path =  shift @_;
    my $owners_group_id = (stat($dir_path))[5];# or die "not a correct path given";
    my $owners_group_name = (getgrgid $owners_group_id)[0];
    return $owners_group_name;
}

sub check_if_part_of_group
{
    my ($dir_path, @groups) = @_;
    my $part_of_group = 0;
    my $owners_group_name = get_owners_group_name($dir_path);
    foreach my $group (@groups)
    {
	if($owners_group_name eq $group)
	{
	    $part_of_group = 1;
	    last;
	}
    }
    return $part_of_group;
}

sub select_which_permission_number
{
    my ($dir_path, @groups) = @_;
    my $oct_permissions = get_dir_permissions($dir_path);
    my @single_permission = split("", $oct_permissions); 
    my $select;

    if(check_if_part_of_group($dir_path, @groups) == 1)
    {
	$select = $single_permission[2];
    }
    else
    {
    	$select = $single_permission[3];
    }
    return $select;    
}

sub get_forbidden_dirs
{
    my ($dir_path, @groups) = @_;
    my @forbidden_dirs;

    my @split_path = split("/",$dir_path);
    my $i = 0;
    foreach my $path (@split_path)
    {
	if($path eq ""){$i++;next;}
	$dir_path = join("/", @split_path[0..$i]);
	my $select = select_which_permission_number($dir_path, @groups);
	my $binary_select = sprintf("%03b", $select);
	
	my $readable = 1;
	my $traversable = 1;
	my $reason = "";
	
	if(($binary_select & 100) != 100)
	{
	    $reason .= "not readable ";
	    $readable = 0;
	}
	if(($binary_select & 001) != 001)
	{
	    $reason .= "not traversable ";
	    $traversable = 0;
	}
	
	if(!$readable || !$traversable)
	{
	    push(@forbidden_dirs, "PATH: $dir_path  REASON: $reason");
	}
	$i++;
    }
    print Dumper \@forbidden_dirs;
    return 1;
}

sub get_globally_readable_dirs
{
    my ($dir_path, @groups) = @_;

    my @globally_readable_dirs;
    my @split_path = split("/",$dir_path);
    my $i = 0;
    foreach my $path (@split_path)
    {
	if($path eq "")
	{
	    push(@globally_readable_dirs, $path);
	    $i++;
	    next;
	}

	$dir_path = join("/", @split_path[0..$i]);
	my $oct_permissions = get_dir_permissions($dir_path);
	my @single_permission = split("", $oct_permissions);
	my $select = $single_permission[3];
	my $binary_select = sprintf("%03b", $select);
	if($binary_select & 100 == 100)
	{
	    push(@globally_readable_dirs, $path);
	}
	else
	{
	    $dir_path = join("/", @globally_readable_dirs);
	    last;
	}
	$i++;
    }
    print "Globally Readable: $dir_path\n";
    return 1;
}

sub run_unit_tests 
{
    require Test::More;
    Test::More->import("no_plan");
    my ($dir_path, @groups) = @_;
    is(get_dir_permissions($dir_path), "0750", "testing get_dir_permissions ");
    is(get_owners_group_name($dir_path), 'soc', "testing get_owner_group_name");
    is(check_if_part_of_group($dir_path, @groups), 0, "testing check_if_part_of_group");
    is(select_which_permission_number($dir_path, @groups), 0, "testing select_which_permission_number");
    is(get_forbidden_dirs($dir_path, @groups), 1, "testing get_forbidden_directories");
    is(get_globally_readable_dirs($dir_path, @groups), 1, "testing get_globally_readable_dirs");
}


1;

